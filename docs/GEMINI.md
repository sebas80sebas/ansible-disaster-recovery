# GEMINI.md - Project Context for Resilience Taskboard

## Project Overview
This project is an **Enterprise-grade Ansible Automation** suite designed for the complete disaster recovery of containerized applications. It features the **Resilience Taskboard**, a Flask-based task manager backed by PostgreSQL, serving as a demonstration platform for backup and recovery strategies.

### Key Technologies
- **Ansible 2.10+**: Core automation engine.
- **Docker & Docker Compose Plugin**: Container orchestration.
- **PostgreSQL 14**: Persistent storage.
- **Flask (Python 3.11)**: Backend API and Frontend.
- **Bootstrap 5**: Modernized UI.
- **Jinja2**: Templating for dynamic configuration.

## Project Structure
- `site.yml`: Main entry point for full system deployment.
- `inventories/`: Environment-specific configurations (`staging`, `production`).
- `roles/`:
  - `common`: System base, Python deps (`python3-docker`), timezone, NTP.
  - `docker`: Docker Engine and Compose Plugin installation (v2).
  - `application`: Resilience Taskboard deployment (Port 8081).
  - `backup`: Automation scripts, cron jobs, and initial setup.
  - `restore`: Disaster recovery procedures.
- `playbooks/`: Individual playbooks for `backup.yml`, `restore.yml`, `simulate_disaster.yml`.

## Deployment & Compatibility
- **OS**: Optimized for **Ubuntu 24.04 Noble**.
- **Python**: Compliant with **PEP 668** (uses system packages instead of pip).
- **Port**: Application runs on **8081** to avoid common conflicts.
- **Docker Command**: Standardized on `docker compose` (plugin).

## Main Commands (Makefile)
| Command | Description |
|---------|-------------|
| `make deploy` | Full system installation. Use `--ask-become-pass`. |
| `make backup` | Trigger manual data backup to `/opt/backups/`. |
| `make disaster` | Simulate total data loss (destructive!). |
| `make restore` | Recover system from the latest backup. |
| `make verify` | Run application health checks. |

## Development Conventions
- **Idempotency**: Playbooks are designed to be run repeatedly without side effects.
- **Raw Blocks**: Use `{% raw %}` for Docker templates to avoid Jinja2 conflicts.
- **Local Testing**: Supports `ansible_connection=local` for zero-SSH testing.