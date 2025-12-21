.PHONY: help install test lint format clean deploy destroy init plan apply

help:
	@echo "Available commands:"
	@echo "  make install    - Install Python dependencies"
	@echo "  make test       - Run tests"
	@echo "  make lint       - Lint code"
	@echo "  make format     - Format code"
	@echo "  make clean      - Clean temporary files"
	@echo "  make init       - Initialize Terraform"
	@echo "  make plan       - Terraform plan"
	@echo "  make apply      - Deploy infrastructure"
	@echo "  make destroy    - Destroy infrastructure"

install:
	pip install -r requirements.txt

test:
	pytest python/tests/ -v

lint:
	flake8 python/
	terraform fmt -check -recursive terraform/

format:
	black python/
	terraform fmt -recursive terraform/

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type d -name .pytest_cache -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true

init:
	cd terraform/environments/dev && terraform init

plan:
	cd terraform/environments/dev && terraform plan

apply:
	cd terraform/environments/dev && terraform apply

destroy:
	cd terraform/environments/dev && terraform destroy
