// Package contracts reads Terraform interfaces without executing Terraform or
// providers. Consumers validate against the exact checked-out module revision.
package contracts

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/ext/typeexpr"
	"github.com/hashicorp/hcl/v2/hclsyntax"
	"github.com/zclconf/go-cty/cty"
	"github.com/zclconf/go-cty/cty/convert"
)

type Variable struct {
	Type         string `json:"type"`
	Required     bool   `json:"required"`
	Sensitive    bool   `json:"sensitive"`
	Nullable     bool   `json:"nullable"`
	ty           cty.Type
	defaults     *typeexpr.Defaults
	defaultValue cty.Value
}
type Output struct {
	Sensitive bool `json:"sensitive"`
}
type Binding struct {
	Path  string   `json:"path"`
	Names []string `json:"names"`
}
type Module struct {
	SHA256    string              `json:"sha256"`
	Variables map[string]Variable `json:"variables"`
	Outputs   map[string]Output   `json:"outputs"`
	Resources []string            `json:"resources"`
	Owners    []string            `json:"owners"`
	Binding   *Binding            `json:"binding,omitempty"`
	Manual    bool                `json:"manual,omitempty"`
}
type Repository struct {
	Version int               `json:"version"`
	Modules map[string]Module `json:"modules"`
}

// Ownership is deployment responsibility, not the presence of a Worker binding.
// Workflows support Terraform for existing scripts and Wrangler for fresh deploys.
func ownership(name string, resources []string) ([]string, *Binding, bool) {
	bindings := map[string]Binding{
		"r2": {"r2_buckets", []string{"DATA"}}, "kv": {"kv_namespaces", []string{"CACHE"}},
		"d1": {"d1_databases", []string{"DB"}}, "queues": {"queues.producers", []string{"JOBS"}},
		"workflows":         {"workflows", []string{"APP_WORKFLOW"}},
		"durable-objects":   {"durable_objects.bindings", []string{"COUNTER", "VoiceAgent"}},
		"containers":        {"durable_objects.bindings", []string{"APP_CONTAINER"}},
		"browser-rendering": {"browser", []string{"BROWSER"}}, "workers-ai": {"ai", []string{"AI"}},
		"vectorize":        {"vectorize", []string{"VECTORIZE"}},
		"analytics-engine": {"analytics_engine_datasets", []string{"ANALYTICS"}}, "images": {"images", []string{"IMAGES"}},
	}
	var binding *Binding
	if b, ok := bindings[name]; ok {
		binding = &b
	}
	if name == "workflows" {
		return []string{"terraform", "wrangler"}, binding, false
	}
	if name == "vpc" {
		return []string{"manual"}, nil, true
	}
	if len(resources) == 0 {
		return []string{"wrangler"}, binding, false
	}
	return []string{"terraform"}, binding, name == "r2-access-logs"
}

func bodies(dir string) ([]*hclsyntax.Body, map[string][]byte, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, nil, err
	}
	var out []*hclsyntax.Body
	files := map[string][]byte{}
	for _, entry := range entries {
		if strings.HasSuffix(entry.Name(), ".tf.json") {
			return nil, nil, fmt.Errorf("Terraform JSON sources require explicit contract support: %s", entry.Name())
		}
		if !strings.HasSuffix(entry.Name(), ".tf") {
			continue
		}
		if !entry.Type().IsRegular() {
			return nil, nil, fmt.Errorf("non-regular Terraform source: %s", entry.Name())
		}
		raw, err := os.ReadFile(filepath.Join(dir, entry.Name()))
		if err != nil {
			return nil, nil, err
		}
		f, d := hclsyntax.ParseConfig(raw, entry.Name(), hcl.InitialPos)
		if d.HasErrors() {
			return nil, nil, fmt.Errorf("%s", d.Error())
		}
		out = append(out, f.Body.(*hclsyntax.Body))
		files[entry.Name()] = raw
	}
	if len(out) == 0 {
		return nil, nil, fmt.Errorf("no Terraform sources in %s", dir)
	}
	return out, files, nil
}
func boolAttr(body *hclsyntax.Body, name string, fallback bool) (bool, error) {
	a := body.Attributes[name]
	if a == nil {
		return fallback, nil
	}
	v, d := a.Expr.Value(nil)
	if d.HasErrors() || !v.IsKnown() || v.IsNull() || !v.Type().Equals(cty.Bool) {
		return false, fmt.Errorf("%s must be a literal boolean", name)
	}
	return v.True(), nil
}
func ReadModule(dir string) (Module, error) {
	m := Module{Variables: map[string]Variable{}, Outputs: map[string]Output{}, Resources: []string{}}
	resourceNames := map[string]bool{}
	bodies, files, err := bodies(dir)
	if err != nil {
		return m, err
	}
	names := make([]string, 0, len(files))
	for n := range files {
		names = append(names, n)
	}
	sort.Strings(names)
	hash := sha256.New()
	for _, n := range names {
		hash.Write([]byte(n))
		hash.Write([]byte{0})
		hash.Write(files[n])
		hash.Write([]byte{0})
	}
	m.SHA256 = hex.EncodeToString(hash.Sum(nil))
	for _, body := range bodies {
		for _, b := range body.Blocks {
			switch b.Type {
			case "variable":
				if len(b.Labels) != 1 {
					return m, fmt.Errorf("invalid variable labels")
				}
				name := b.Labels[0]
				if _, ok := m.Variables[name]; ok {
					return m, fmt.Errorf("duplicate variable %s", name)
				}
				v := Variable{Required: b.Body.Attributes["default"] == nil, Nullable: true, ty: cty.DynamicPseudoType, Type: "any"}
				if a := b.Body.Attributes["type"]; a != nil {
					ty, defaults, d := typeexpr.TypeConstraintWithDefaults(a.Expr)
					if d.HasErrors() {
						return m, fmt.Errorf("variable %s: %s", name, d.Error())
					}
					v.ty, v.defaults = ty, defaults
					r := a.Expr.Range()
					v.Type = strings.TrimSpace(string(files[r.Filename][r.Start.Byte:r.End.Byte]))
				}
				v.Sensitive, err = boolAttr(b.Body, "sensitive", false)
				if err != nil {
					return m, err
				}
				v.Nullable, err = boolAttr(b.Body, "nullable", true)
				if err != nil {
					return m, err
				}
				if a := b.Body.Attributes["default"]; a != nil {
					value, d := a.Expr.Value(nil)
					if d.HasErrors() || !value.IsWhollyKnown() {
						return m, fmt.Errorf("variable %s default must be constant", name)
					}
					if value.IsNull() && !v.Nullable {
						return m, fmt.Errorf("variable %s default cannot be null", name)
					}
					if v.defaults != nil {
						value = v.defaults.Apply(value)
					}
					value, err = convert.Convert(value, v.ty)
					if err != nil {
						return m, fmt.Errorf("variable %s default has incompatible type", name)
					}
					v.defaultValue = value
				}
				m.Variables[name] = v
			case "output":
				if len(b.Labels) != 1 {
					return m, fmt.Errorf("invalid output labels")
				}
				n := b.Labels[0]
				if _, ok := m.Outputs[n]; ok {
					return m, fmt.Errorf("duplicate output %s", n)
				}
				sensitive, e := boolAttr(b.Body, "sensitive", false)
				if e != nil {
					return m, e
				}
				m.Outputs[n] = Output{Sensitive: sensitive}
			case "resource":
				if len(b.Labels) != 2 {
					return m, fmt.Errorf("invalid resource labels")
				}
				resource := b.Labels[0] + "." + b.Labels[1]
				if resourceNames[resource] {
					return m, fmt.Errorf("duplicate resource %s", resource)
				}
				resourceNames[resource] = true
				m.Resources = append(m.Resources, resource)
			}
		}
	}
	sort.Strings(m.Resources)
	m.Owners, m.Binding, m.Manual = ownership(filepath.Base(dir), m.Resources)
	return m, nil
}
func ReadRepository(root string) (Repository, error) {
	r := Repository{Version: 1, Modules: map[string]Module{}}
	entries, err := os.ReadDir(filepath.Join(root, "modules"))
	if err != nil {
		return r, err
	}
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		m, err := ReadModule(filepath.Join(root, "modules", e.Name()))
		if err != nil {
			return r, fmt.Errorf("%s: %w", e.Name(), err)
		}
		r.Modules[e.Name()] = m
	}
	return r, nil
}
func (r Repository) JSON() ([]byte, error) {
	raw, err := json.MarshalIndent(r, "", "  ")
	return append(raw, '\n'), err
}

// ValidateInputs follows Terraform conversions, including optional object
// defaults. Values come from HCL's typed unknown context, never runtime secrets.
func (m Module) ValidateInputs(attrs hclsyntax.Attributes, ctx *hcl.EvalContext) error {
	for n, v := range m.Variables {
		if v.Required && attrs[n] == nil {
			return fmt.Errorf("missing required input %s", n)
		}
	}
	for n, a := range attrs {
		if n == "source" {
			continue
		}
		v, ok := m.Variables[n]
		if !ok {
			return fmt.Errorf("unknown input %s", n)
		}
		value, d := a.Expr.Value(ctx)
		if d.HasErrors() {
			return fmt.Errorf("input %s expression cannot be checked", n)
		}
		if value.IsNull() && !v.Nullable {
			if v.defaultValue == cty.NilVal {
				return fmt.Errorf("input %s is not nullable", n)
			}
			value = v.defaultValue
		}
		if v.defaults != nil {
			value = v.defaults.Apply(value)
		}
		if _, err := convert.Convert(value, v.ty); err != nil {
			return fmt.Errorf("input %s: incompatible type (%s)", n, err)
		}
	}
	return nil
}
func (m Module) AllowsOwner(owner string) bool {
	for _, o := range m.Owners {
		if o == owner {
			return true
		}
	}
	return false
}

// UnknownValues supplies static input types without exposing deployment values.
func (m Module) UnknownValues() map[string]cty.Value {
	out := map[string]cty.Value{}
	for name, v := range m.Variables {
		out[name] = cty.UnknownVal(v.ty)
	}
	return out
}

// ValidateBinding checks every environment independently. Container/DO names
// use Wrangler's name field; all other bindings use binding.
func (m Module) ValidateBinding(env map[string]any) error {
	if m.Binding == nil {
		return nil
	}
	var value any = env
	for _, key := range strings.Split(m.Binding.Path, ".") {
		obj, ok := value.(map[string]any)
		if !ok {
			return fmt.Errorf("missing binding path %s", m.Binding.Path)
		}
		value = obj[key]
	}
	entries, array := value.([]any)
	singleton := m.Binding.Path == "browser" || m.Binding.Path == "ai" || m.Binding.Path == "images"
	if singleton {
		if _, ok := value.(map[string]any); !ok {
			return fmt.Errorf("binding path %s requires an object", m.Binding.Path)
		}
		entries = []any{value}
	} else if !array {
		return fmt.Errorf("binding path %s requires an array", m.Binding.Path)
	}
	for _, e := range entries {
		obj, ok := e.(map[string]any)
		if !ok {
			continue
		}
		field := "binding"
		if m.Binding.Path == "durable_objects.bindings" {
			field = "name"
		}
		n, _ := obj[field].(string)
		for _, want := range m.Binding.Names {
			if n == want {
				return nil
			}
		}
	}
	return fmt.Errorf("missing binding %s in %s", strings.Join(m.Binding.Names, "/"), m.Binding.Path)
}
