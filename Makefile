.DEFAULT_GOAL := help
ANSIBLE_DIR := ansible

export ANSIBLE_CONFIG := $(CURDIR)/$(ANSIBLE_DIR)/ansible.cfg

.PHONY: help
help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-28s\033[0m %s\n", $$1, $$2}'

.PHONY: install
install: ## Install pre-commit hooks, Ansible collections, and commitlint
	pre-commit install --hook-type pre-commit --hook-type commit-msg
	cd $(ANSIBLE_DIR) && ansible-galaxy collection install -r requirements.yml -p collections
	npm ci --ignore-scripts

.PHONY: lint
lint: ## Run all linters via pre-commit
	pre-commit run --all-files

.PHONY: molecule
molecule: ## Run Molecule tests for all roles (podman)
	@for role in $(ANSIBLE_DIR)/roles/*/; do \
		if [ -d "$$role/molecule" ]; then \
			echo "=== Testing $$(basename $$role) ==="; \
			(cd "$$role" && molecule test) || exit 1; \
		fi; \
	done

.PHONY: galaxy
galaxy: ## Install Ansible Galaxy collections from requirements.yml
	cd $(ANSIBLE_DIR) && ansible-galaxy collection install -r requirements.yml -p collections

.PHONY: play
play: ## Run the site playbook against ferro43
	ansible-playbook $(ANSIBLE_DIR)/playbooks/site.yml

.PHONY: apply-branch-protection
apply-branch-protection: ## Apply branch protection rules to GitHub
	tooling/repo-config/apply-branch-protection.sh

.PHONY: check-protection-drift
check-protection-drift: ## Check for drift between live and declared branch protection
	tooling/repo-config/check-protection-drift.sh
