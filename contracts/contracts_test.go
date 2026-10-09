package contracts

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"sort"
	"strings"
	"testing"
	"time"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclsyntax"
	"github.com/zclconf/go-cty/cty"
)

func writeSource(t *testing.T, dir, name, source string) {
	t.Helper()
	if err := os.MkdirAll(dir, 0755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, name), []byte(source), 0644); err != nil {
		t.Fatal(err)
	}
}

func fixtureModule(t *testing.T, source string) Module {
	t.Helper()
	dir := t.TempDir()
	writeSource(t, dir, "variables.tf", source)
	m, err := ReadModule(dir)
	if err != nil {
		t.Fatal(err)
	}
	return m
}

func inputAttrs(t *testing.T, source string) hclsyntax.Attributes {
	t.Helper()
	f, diagnostics := hclsyntax.ParseConfig([]byte(source), "inputs.tf", hcl.InitialPos)
	if diagnostics.HasErrors() {
		t.Fatal(diagnostics.Error())
	}
	return f.Body.(*hclsyntax.Body).Attributes
}

func TestRepositorySnapshotAndCheckCommand(t *testing.T) {
	root := ".."
	repository, err := ReadRepository(root)
	if err != nil {
		t.Fatal(err)
	}
	if repository.Version != 1 || len(repository.Modules) != 27 {
		t.Fatalf("unexpected module inventory: version=%d modules=%d", repository.Version, len(repository.Modules))
	}
	raw, err := repository.JSON()
	if err != nil {
		t.Fatal(err)
	}
	stored, err := os.ReadFile(filepath.Join(root, "contracts", "modules.json"))
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(raw, stored) {
		t.Fatal("actual 27-module interface snapshot has drifted")
	}
	if len(raw) == 0 || raw[len(raw)-1] != '\n' {
		t.Fatal("snapshot lacks final newline")
	}
	again, err := ReadRepository(root)
	if err != nil {
		t.Fatal(err)
	}
	againRaw, _ := again.JSON()
	if !bytes.Equal(raw, againRaw) {
		t.Fatal("snapshot is nondeterministic")
	}
	if !repository.Modules["d1"].Variables["databases"].Required || repository.Modules["d1"].Variables["databases"].Nullable {
		t.Fatal("actual D1 required/nonnullable contract lost")
	}
	if !repository.Modules["workflows"].AllowsOwner("terraform") || !repository.Modules["workflows"].AllowsOwner("wrangler") {
		t.Fatal("workflow dual ownership lost")
	}
	if !repository.Modules["vpc"].Manual || repository.Modules["vpc"].Binding != nil {
		t.Fatal("VPC manual contract lost")
	}

	// Execute the real check command against a complete isolated copy: stale
	// provenance must fail without rewriting the stored artifact.
	isolated := t.TempDir()
	entries, err := os.ReadDir(filepath.Join(root, "modules"))
	if err != nil {
		t.Fatal(err)
	}
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		files, err := os.ReadDir(filepath.Join(root, "modules", entry.Name()))
		if err != nil {
			t.Fatal(err)
		}
		for _, file := range files {
			if !strings.HasSuffix(file.Name(), ".tf") {
				continue
			}
			source, err := os.ReadFile(filepath.Join(root, "modules", entry.Name(), file.Name()))
			if err != nil {
				t.Fatal(err)
			}
			writeSource(t, filepath.Join(isolated, "modules", entry.Name()), file.Name(), string(source))
		}
	}
	writeSource(t, filepath.Join(isolated, "contracts"), "modules.json", string(stored))
	check := func(wantFailure bool) {
		t.Helper()
		cmd := exec.Command("go", "run", "./cmd/module-contracts", "-root", isolated, "-check")
		cmd.Dir = root
		output, err := cmd.CombinedOutput()
		if wantFailure {
			if err == nil || !strings.Contains(string(output), "module contract drift") {
				t.Fatalf("stale snapshot accepted: err=%v output=%s", err, output)
			}
		} else if err != nil || !strings.Contains(string(output), "PASS: 27 module contracts") {
			t.Fatalf("valid snapshot rejected: err=%v output=%s", err, output)
		}
	}
	check(false)
	changed := filepath.Join(isolated, "modules", "r2", "variables.tf")
	source, err := os.ReadFile(changed)
	if err != nil {
		t.Fatal(err)
	}
	writeSource(t, filepath.Dir(changed), filepath.Base(changed), string(source)+"\n# provenance-only change\n")
	check(true)
	unchanged, err := os.ReadFile(filepath.Join(isolated, "contracts", "modules.json"))
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(unchanged, stored) {
		t.Fatal("check command rewrote stale artifact")
	}
}

func TestModuleHashesAndSensitiveMetadata(t *testing.T) {
	dir := t.TempDir()
	sources := map[string]string{
		"z.tf": "resource \"cloudflare_r2_bucket\" \"data\" {}\noutput \"credential\" {\n sensitive = true\n value = \"not-exported-secret\"\n}\n",
		"a.tf": "variable \"credential\" {\n type = string\n sensitive = true\n default = \"not-exported-secret\"\n}\nresource \"cloudflare_dns_record\" \"record\" {}\n",
	}
	for name, source := range sources {
		writeSource(t, dir, name, source)
	}
	writeSource(t, dir, "ignored.txt", "not HCL")
	m, err := ReadModule(dir)
	if err != nil {
		t.Fatal(err)
	}
	names := make([]string, 0, len(sources))
	for name := range sources {
		names = append(names, name)
	}
	sort.Strings(names)
	hash := sha256.New()
	for _, name := range names {
		hash.Write([]byte(name))
		hash.Write([]byte{0})
		hash.Write([]byte(sources[name]))
		hash.Write([]byte{0})
	}
	if m.SHA256 != hex.EncodeToString(hash.Sum(nil)) {
		t.Fatal("hash does not bind exact sorted filenames and source bytes")
	}
	if !reflect.DeepEqual(m.Resources, []string{"cloudflare_dns_record.record", "cloudflare_r2_bucket.data"}) {
		t.Fatalf("resource inventory: %v", m.Resources)
	}
	if !m.Variables["credential"].Sensitive || m.Variables["credential"].Required || !m.Outputs["credential"].Sensitive {
		t.Fatal("sensitive/default metadata lost")
	}
	raw, err := (Repository{Version: 1, Modules: map[string]Module{"fixture": m}}).JSON()
	if err != nil {
		t.Fatal(err)
	}
	if bytes.Contains(raw, []byte("not-exported-secret")) {
		t.Fatal("snapshot exposes default/output values")
	}
	for _, name := range names {
		writeSource(t, dir, name, sources[name]+"\n# exact bytes changed\n")
		changed, err := ReadModule(dir)
		if err != nil {
			t.Fatal(err)
		}
		if changed.SHA256 == m.SHA256 {
			t.Fatalf("%s drift not detected", name)
		}
		writeSource(t, dir, name, sources[name])
	}
	if err := os.Rename(filepath.Join(dir, "a.tf"), filepath.Join(dir, "b.tf")); err != nil {
		t.Fatal(err)
	}
	renamed, err := ReadModule(dir)
	if err != nil {
		t.Fatal(err)
	}
	if renamed.SHA256 == m.SHA256 {
		t.Fatal("filename drift not detected")
	}
}

func TestInputValidationAndTerraformDefaults(t *testing.T) {
	m := fixtureModule(t, `
variable "required" {
 type = string
 nullable = false
}
variable "count" {
 type = number
 default = 4
 nullable = false
}
variable "nullable" {
 type = string
 default = null
}
variable "secret" {
 type = string
 sensitive = true
 default = "not-exported-secret"
}
variable "settings" {
 type = object({ nested = optional(object({ enabled = optional(bool, true) }), {}), labels = optional(list(string), []) })
 default = {}
}
variable "items" {
 type = list(object({ name = string, enabled = optional(bool, true) }))
 default = []
}
`)
	cases := []struct{ name, source, errorContains string }{
		{"required missing", `count = 1`, "missing required input required"},
		{"unknown input", "required = \"ok\"\ntypo = true", "unknown input typo"},
		{"required null", `required = null`, "not nullable"},
		{"primitive conversion", "required = 12\ncount = \"5\"", ""},
		{"incompatible type", "required = \"ok\"\ncount = { bad = true }", "incompatible type"},
		{"nullable null", "required = \"ok\"\nnullable = null", ""},
		{"nonnullable default on null", "required = \"ok\"\ncount = null", ""},
		{"optional object defaults", "required = \"ok\"\nsettings = {}\nitems = [{name = \"one\"}, {name = \"two\", enabled = null}]", ""},
		{"optional defaults null", "required = \"ok\"\nsettings = {nested = null, labels = null}", ""},
		{"nested required missing", "required = \"ok\"\nitems = [{}]", "incompatible type"},
		{"nested incompatible", "required = \"ok\"\nsettings = {nested = {enabled = []}}", "incompatible type"},
		{"unevaluable expression", `required = var.missing`, "expression cannot be checked"},
		{"source ignored", "source = \"../modules/r2\"\nrequired = \"ok\"", ""},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			err := m.ValidateInputs(inputAttrs(t, tc.source), nil)
			if tc.errorContains == "" {
				if err != nil {
					t.Fatal(err)
				}
				return
			}
			if err == nil || !strings.Contains(err.Error(), tc.errorContains) {
				t.Fatalf("want %q, got %v", tc.errorContains, err)
			}
			if strings.Contains(err.Error(), "not-exported-secret") {
				t.Fatal("validation exposed sensitive value")
			}
		})
	}
	unknown := m.UnknownValues()
	if len(unknown) != len(m.Variables) || unknown["count"].IsKnown() || !unknown["count"].Type().Equals(cty.Number) {
		t.Fatal("typed unknown context lost")
	}
	ctx := &hcl.EvalContext{Variables: map[string]cty.Value{"var": cty.ObjectVal(unknown)}}
	if err := m.ValidateInputs(inputAttrs(t, "required = var.required\ncount = var.count\nsettings = var.settings"), ctx); err != nil {
		t.Fatal(err)
	}
	if err := m.ValidateInputs(inputAttrs(t, "required = var.required\ncount = var.settings"), ctx); err == nil {
		t.Fatal("incompatible typed unknown accepted")
	}
}

func TestInvalidSourcesAndDeclarations(t *testing.T) {
	if dir := os.Getenv("CF_TF_FIFO_TEST_DIR"); dir != "" {
		if _, err := ReadModule(dir); err == nil || !strings.Contains(err.Error(), "non-regular Terraform source") {
			t.Fatalf("FIFO not rejected before open: %v", err)
		}
		return
	}
	cases := []struct{ name, first, second, errorContains string }{
		{"syntax", `variable "broken" {`, "", ""},
		{"variable labels", `variable "one" "two" {}`, "", "invalid variable labels"},
		{"output labels", `output "one" "two" {}`, "", "invalid output labels"},
		{"resource labels", `resource "one" {}`, "", "invalid resource labels"},
		{"invalid type", "variable \"a\" {\n type = imaginary\n}", "", "variable a"},
		{"nonboolean sensitive", "variable \"a\" {\n sensitive = \"true\"\n}", "", "literal boolean"},
		{"null nullable", "variable \"a\" {\n nullable = null\n}", "", "literal boolean"},
		{"dynamic boolean", "output \"a\" {\n sensitive = var.flag\n}", "", "literal boolean"},
		{"duplicate variable", `variable "a" {}`, `variable "a" {}`, "duplicate variable a"},
		{"duplicate output", `output "a" {}`, `output "a" {}`, "duplicate output a"},
		{"duplicate resource", `resource "cloudflare_r2_bucket" "a" {}`, `resource "cloudflare_r2_bucket" "a" {}`, "duplicate resource"},
		{"incompatible default", "variable \"a\" {\n type = number\n default = {}\n}", "", "default"},
		{"nonliteral default", "variable \"a\" {\n type = string\n default = var.secret\n}", "", "default"},
		{"nonnullable null default", "variable \"a\" {\n type = string\n nullable = false\n default = null\n}", "", "default"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			dir := t.TempDir()
			writeSource(t, dir, "a.tf", tc.first)
			if tc.second != "" {
				writeSource(t, dir, "b.tf", tc.second)
			}
			_, err := ReadModule(dir)
			if err == nil || !strings.Contains(err.Error(), tc.errorContains) {
				t.Fatalf("want rejection %q, got %v", tc.errorContains, err)
			}
		})
	}
	t.Run("empty and missing roots", func(t *testing.T) {
		if _, err := ReadModule(t.TempDir()); err == nil {
			t.Fatal("empty source directory accepted")
		}
		if _, err := ReadRepository(t.TempDir()); err == nil {
			t.Fatal("missing modules accepted")
		}
		root := t.TempDir()
		writeSource(t, filepath.Join(root, "modules", "broken-module"), "main.tf", "broken {")
		if _, err := ReadRepository(root); err == nil || !strings.Contains(err.Error(), "broken-module:") {
			t.Fatalf("module name missing from error: %v", err)
		}
	})
	t.Run("symlink and directory sources", func(t *testing.T) {
		target := t.TempDir()
		writeSource(t, target, "source", `variable "a" {}`)
		dir := t.TempDir()
		if err := os.Symlink(filepath.Join(target, "source"), filepath.Join(dir, "linked.tf")); err != nil {
			t.Fatal(err)
		}
		if _, err := ReadModule(dir); err == nil || !strings.Contains(err.Error(), "non-regular") {
			t.Fatalf("symlink accepted: %v", err)
		}
		dir = t.TempDir()
		if err := os.Mkdir(filepath.Join(dir, "folder.tf"), 0755); err != nil {
			t.Fatal(err)
		}
		if _, err := ReadModule(dir); err == nil || !strings.Contains(err.Error(), "non-regular") {
			t.Fatalf("directory accepted: %v", err)
		}
	})
	t.Run("JSON source fails closed", func(t *testing.T) {
		dir := t.TempDir()
		writeSource(t, dir, "main.tf", `variable "a" {}`)
		writeSource(t, dir, "extra.tf.json", `{"variable":{"hidden":{"type":"string"}}}`)
		if _, err := ReadModule(dir); err == nil || !strings.Contains(err.Error(), "JSON sources") {
			t.Fatalf("unparsed Terraform JSON accepted: %v", err)
		}
	})
	t.Run("FIFO source fails before opening", func(t *testing.T) {
		mkfifo, err := exec.LookPath("mkfifo")
		if err != nil {
			t.Skip("mkfifo unavailable on this platform")
		}
		dir := t.TempDir()
		if output, err := exec.Command(mkfifo, filepath.Join(dir, "blocked.tf")).CombinedOutput(); err != nil {
			t.Fatalf("create isolated FIFO: %v %s", err, output)
		}
		// Run the parser in a bounded subprocess so a future regression cannot
		// hang the test runner on ReadFile of an unopened named pipe.
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		cmd := exec.CommandContext(ctx, os.Args[0], "-test.run=^TestInvalidSourcesAndDeclarations$", "-test.timeout=4s")
		cmd.Env = append(os.Environ(), "CF_TF_FIFO_TEST_DIR="+dir)
		output, err := cmd.CombinedOutput()
		if ctx.Err() != nil || err != nil {
			t.Fatalf("FIFO not rejected before open: err=%v deadline=%v output=%s", err, ctx.Err(), output)
		}
	})
}

func TestOwnershipAndEnvironmentBindingScope(t *testing.T) {
	repository, err := ReadRepository("..")
	if err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct {
		module, owner string
		manual        bool
	}{
		{"r2", "terraform", false}, {"workflows", "terraform", false}, {"workflows", "wrangler", false},
		{"workers-ai", "wrangler", false}, {"browser-rendering", "wrangler", false}, {"vpc", "manual", true}, {"r2-access-logs", "terraform", true},
	} {
		t.Run(tc.module+"/"+tc.owner, func(t *testing.T) {
			m := repository.Modules[tc.module]
			if !m.AllowsOwner(tc.owner) || m.Manual != tc.manual || m.AllowsOwner("Terraform") || m.AllowsOwner("unknown") {
				t.Fatalf("unexpected ownership: %+v", m.Owners)
			}
		})
	}
	for _, name := range []string{"r2", "kv", "d1", "queues", "workflows", "durable-objects", "containers", "browser-rendering", "workers-ai", "vectorize", "analytics-engine", "images"} {
		t.Run(name+" binding", func(t *testing.T) {
			m := repository.Modules[name]
			if m.Binding == nil {
				t.Fatal("expected binding")
			}
			field, wrongField := "binding", "name"
			if m.Binding.Path == "durable_objects.bindings" {
				field, wrongField = "name", "binding"
			}
			environment := func(value any) map[string]any {
				root := map[string]any{}
				current := root
				parts := strings.Split(m.Binding.Path, ".")
				for _, part := range parts[:len(parts)-1] {
					next := map[string]any{}
					current[part] = next
					current = next
				}
				current[parts[len(parts)-1]] = value
				return root
			}
			singleton := name == "browser-rendering" || name == "workers-ai" || name == "images"
			validValue := func(field, binding string) any {
				if singleton {
					return map[string]any{field: binding}
				}
				return []any{nil, "ignored", map[string]any{field: "OTHER"}, map[string]any{field: binding}}
			}
			for _, allowed := range m.Binding.Names {
				preview := environment(validValue(field, allowed))
				if err := m.ValidateBinding(preview); err != nil {
					t.Fatal(err)
				}
				if err := m.ValidateBinding(environment(validValue(wrongField, allowed))); err == nil {
					t.Fatal("wrong Wrangler field accepted")
				}
				var invalidShape any = map[string]any{field: allowed}
				if singleton {
					invalidShape = []any{invalidShape}
				}
				if err := m.ValidateBinding(environment(invalidShape)); err == nil {
					t.Fatal("wrong Wrangler binding shape accepted")
				}
				if err := m.ValidateBinding(map[string]any{"env": map[string]any{"preview": preview}}); err == nil {
					t.Fatal("preview binding incorrectly covers separate environment")
				}
			}
			for _, bad := range []map[string]any{{}, environment(nil), environment([]any{}), environment(map[string]any{field: 123}), environment(map[string]any{field: "OTHER"})} {
				if err := m.ValidateBinding(bad); err == nil {
					t.Fatalf("missing/wrong environment binding accepted: %#v", bad)
				}
			}
		})
	}
	if err := repository.Modules["vpc"].ValidateBinding(nil); err != nil {
		t.Fatal(err)
	}
}
