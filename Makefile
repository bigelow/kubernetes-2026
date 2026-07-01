.PHONY: validate fmt plan clean lint

validate:
	python3 scripts/test_validate.py
	python3 scripts/validate.py
	terraform fmt -check -recursive terraform/
	$(MAKE) lint

# Static IaC analysis. Guarded so `make validate` still runs on machines without
# the scanners installed — CI (the iac-scan job) is the authoritative gate.
# When a tool IS present, its exit code propagates so real findings fail the build.
lint:
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --init >/dev/null && tflint --chdir=terraform --recursive; \
	else echo "tflint not installed — skipping (CI is the gate)"; fi
	@if command -v trivy >/dev/null 2>&1; then \
		trivy config --exit-code 1 --skip-dirs '**/.terraform' .; \
	else echo "trivy not installed — skipping (CI is the gate)"; fi

fmt:
	terraform fmt -recursive terraform/

plan:
	cd terraform/environments/example-prod && terraform init && terraform plan

clean:
	find . -name "*.tfstate*" -delete
	find . -name ".terraform" -type d -prune -exec rm -rf {} \;
