.PHONY: help deploy backup restore disaster verify test clean

# Ensure we use bash for shell commands (needed for read -p)
SHELL := /bin/bash

# Default environment
ENV ?= staging
INVENTORY = inventories/$(ENV)/hosts

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m # No Color

help: ## Show this help message
	@echo "Ansible Disaster Recovery - Available Commands"
	@echo "==============================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Usage: make <command> [ENV=staging|production]"
	@echo "Default environment: $(ENV)"

check: ## Check Ansible syntax
	@echo "$(GREEN)Checking Ansible syntax...$(NC)"
	@ansible-playbook site.yml --syntax-check
	@ansible-playbook playbooks/backup.yml --syntax-check
	@ansible-playbook playbooks/restore.yml --syntax-check
	@ansible-playbook playbooks/simulate_disaster.yml --syntax-check
	@ansible-playbook playbooks/verify.yml --syntax-check
	@echo "$(GREEN)[OK] Syntax check passed$(NC)"

ping: ## Test connectivity to hosts
	@echo "$(GREEN)Testing connectivity to $(ENV) hosts...$(NC)"
	@ansible -i $(INVENTORY) all -m ping

deploy: ## Deploy complete infrastructure
	@echo -e "$(YELLOW)Deploying to $(ENV)...$(NC)"
	@ansible-playbook -i $(INVENTORY) site.yml --ask-become-pass

deploy-staging: ## Deploy to staging
	@$(MAKE) deploy ENV=staging

deploy-production: ## Deploy to production (requires vault password)
	@$(MAKE) deploy ENV=production --ask-vault-pass --ask-become-pass

backup: ## Perform manual backup
	@echo -e "$(GREEN)Creating backup on $(ENV)...$(NC)"
	@ansible-playbook -i $(INVENTORY) playbooks/backup.yml --ask-become-pass

restore: ## Restore from latest backup
	@echo -e "$(RED)WARNING: This will restore from backup!$(NC)"
	@echo -e "Environment: $(ENV)"
	@read -p "Press Enter to continue or Ctrl+C to abort..."
	@ansible-playbook -i $(INVENTORY) playbooks/restore.yml --ask-become-pass

disaster: ## Simulate disaster (DESTRUCTIVE!)
	@echo -e "$(RED)DANGER: This will destroy all data!$(NC)"
	@echo -e "Environment: $(ENV)"
	@read -p "Type 'destroy' to continue: " confirm; \
	if [ "$$confirm" = "destroy" ]; then \
		ansible-playbook -i $(INVENTORY) playbooks/simulate_disaster.yml --ask-become-pass; \
	else \
		echo -e "$(YELLOW)Aborted$(NC)"; \
	fi

verify: ## Verify application health
	@echo -e "$(GREEN)Verifying $(ENV) application...$(NC)"
	@ansible-playbook -i $(INVENTORY) playbooks/verify.yml --ask-become-pass

test: ## Run complete DR test
	@echo "$(YELLOW)Running complete DR test on $(ENV)...$(NC)"
	@./scripts/full_dr_test.sh $(INVENTORY)

status: ## Show backup status
	@echo "$(GREEN)Backup status for $(ENV):$(NC)"
	@ansible -i $(INVENTORY) backup_servers -a "/opt/backup_scripts/check_backup_status.sh"

logs: ## Show application logs
	@echo "$(GREEN)Application logs for $(ENV):$(NC)"
	@ansible -i $(INVENTORY) app_servers -a "docker logs --tail 50 todoapp_app"

clean: ## Clean up temporary files
	@echo "$(GREEN)Cleaning up...$(NC)"
	@rm -f *.retry
	@rm -f ansible.log
	@rm -f /tmp/dr_*.log
	@rm -f /tmp/pre_disaster_state.json
	@echo "$(GREEN)[OK] Cleanup complete$(NC)"

vault-create: ## Create new vault file
	@echo "$(GREEN)Creating vault file for $(ENV)...$(NC)"
	@ansible-vault create inventories/$(ENV)/group_vars/vault.yml

vault-edit: ## Edit vault file
	@echo "$(GREEN)Editing vault file for $(ENV)...$(NC)"
	@ansible-vault edit inventories/$(ENV)/group_vars/vault.yml

vault-view: ## View vault file
	@ansible-vault view inventories/$(ENV)/group_vars/vault.yml

# Quick commands
up: deploy ## Alias for deploy
down: disaster ## Alias for disaster (DESTRUCTIVE!)
dr: restore ## Alias for restore

# Useful combinations
full-test: deploy backup disaster restore verify ## Complete DR workflow
quick-check: check ping verify ## Quick health check

.DEFAULT_GOAL := help
