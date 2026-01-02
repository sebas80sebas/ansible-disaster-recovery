# GEMINI.md - Project Context for Ansible Disaster Recovery

## Project Overview
This project is an **Enterprise-level Ansible Automation** suite designed for the complete disaster recovery of containerized applications (Flask + PostgreSQL). It follows Infrastructure as Code (IaC) principles to ensure idempotent deployments and reliable recovery procedures.

### Key Technologies
- **Ansible 2.9+**: Core automation engine.
- **Docker & Docker Compose**: Container orchestration.
- **PostgreSQL**: Database for application data.
- **Flask (Python)**: Application framework.
- **Jinja2**: Templating for configurations.
- **Makefile**: Command abstraction layer.

## Project Structure
- `site.yml`: Main entry point for full deployment.
- `inventories/`: Environment-specific configurations (`staging`, `production`).
- `roles/`: Modular automation logic (`common`, `docker`, `application`, `backup`, `restore`).
- `playbooks/`: Specific task playbooks (`backup.yml`, `restore.yml`, `simulate_disaster.yml`, `verify.yml`).
- `scripts/`: Utility scripts for testing (e.g., `full_dr_test.sh`).
- `docs/`: Detailed documentation for deployment, DR, and testing.

## Building and Running
The project uses a `Makefile` to simplify operations.

### Main Commands
| Command | Description |
|---------|-------------|
| `make deploy` | Deploy the full stack to the default environment (staging). |
| `make backup` | Trigger a manual backup of volumes, database, and configs. |
| `make disaster` | Simulate a catastrophic failure (removes containers/data). |
| `make restore` | Perform a full recovery from the latest backup. |
| `make verify` | Run health checks to confirm application integrity. |
| `make test` | Execute the end-to-end Disaster Recovery test suite. |

### Configuration
- **Inventory**: Modify `inventories/staging/hosts` or `inventories/production/hosts` to point to your target servers.
- **Secrets**: Use `make vault-create` to manage sensitive data via Ansible Vault.

## Development Conventions
- **Idempotency**: All playbooks must be safe to run multiple times.
- **Variables**: Prefer group variables in `inventories/` over hardcoding in roles.
- **Tags**: Use tags (e.g., `common`, `docker`, `application`) for selective execution.
- **Testing**: Always run `make check` (syntax check) before committing changes.
- **Documentation**: Update the relevant `.md` files in `docs/` when modifying core logic.
