.PHONY: validate fmt plan clean

validate:
	python3 scripts/test_validate.py
	python3 scripts/validate.py
	terraform fmt -check -recursive terraform/

fmt:
	terraform fmt -recursive terraform/

plan:
	cd terraform/environments/example-prod && terraform init && terraform plan

clean:
	find . -name "*.tfstate*" -delete
	find . -name ".terraform" -type d -prune -exec rm -rf {} \;
