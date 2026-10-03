.PHONY: check

check:
	python3 scripts/check-architecture.py
	terraform fmt -check -recursive
	terraform -chdir=modules/application init -backend=false -input=false
	terraform -chdir=modules/application validate
	terraform -chdir=modules/application test
	terraform -chdir=examples/application init -backend=false -input=false
	terraform -chdir=examples/application validate
