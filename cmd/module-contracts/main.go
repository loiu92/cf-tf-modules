package main

import (
	"bytes"
	"flag"
	"fmt"
	"github.com/loiu92/cf-tf-modules/contracts"
	"os"
	"path/filepath"
)

func main() {
	root := flag.String("root", ".", "module repository root")
	check := flag.Bool("check", false, "fail on contract drift")
	flag.Parse()
	r, err := contracts.ReadRepository(*root)
	if err != nil {
		fail(err)
	}
	raw, err := r.JSON()
	if err != nil {
		fail(err)
	}
	path := filepath.Join(*root, "contracts", "modules.json")
	if *check {
		stored, err := os.ReadFile(path)
		if err != nil {
			fail(err)
		}
		if !bytes.Equal(raw, stored) {
			fail(fmt.Errorf("module contract drift: run go run ./cmd/module-contracts"))
		}
	} else if err := os.WriteFile(path, raw, 0644); err != nil {
		fail(err)
	}
	fmt.Printf("PASS: %d module contracts\n", len(r.Modules))
}
func fail(err error) { fmt.Fprintln(os.Stderr, err); os.Exit(1) }
