# Resilience Taskboard - Ansible Disaster Recovery

[![Ansible](https://img.shields.io/badge/Ansible-2.10%2B-EE0000?style=flat&logo=ansible)](https://www.ansible.com/)
[![Docker](https://img.shields.io/badge/Docker-24%2B-2496ED?style=flat&logo=docker)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A production-ready Ansible project that automates disaster recovery for the **Resilience Taskboard**, a containerized Flask application with PostgreSQL storage.

## 🎯 Project Overview

This project demonstrates enterprise-level DevOps practices for automated backup and recovery, including:

- **Zero-to-Production** infrastructure provisioning.
- **Modern UI**: Redesigned frontend using Bootstrap 5.
- **Multi-layer Backups**: Automation for Docker volumes, databases, and configs.
- **One-command Recovery**: Seamless restoration from catastrophic failures.
- **Ubuntu 24.04 Ready**: Fully compliant with modern security and Python standards (PEP 668).

## 🚀 Quick Start

### 1. Configure Local Environment
To test directly on your machine, edit `inventories/staging/hosts`:
```ini
[app_servers]
localhost ansible_connection=local

[staging:children]
app_servers
db_servers
backup_servers
```

### 2. Deploy
```bash
# Deploys App on port 8081
ansible-playbook -i inventories/staging/hosts site.yml --ask-become-pass
```

### 3. Disaster & Recovery Test
```bash
make backup ENV=staging    # Create a restore point
make disaster ENV=staging  # Delete all data
make restore ENV=staging   # Bring it back to life
```

## 📊 Recovery Metrics (RTO)

| Operation | Time | Description |
|-----------|------|-------------|
| Full Backup | 2 min | DB dump + Volume compression |
| Recovery | 3-5 min | Restore + Container restart |
| **Total RTO** | **< 10 min** | From crash to fully operational |

## 🛠️ Troubleshooting & Ubuntu 24.04 Tips

- **Python Errors**: The project uses `python3-docker` system packages to avoid `externally-managed-environment` errors.
- **Docker Repository**: If you see GPG conflicts, the automation handles `Signed-By` correctly, but you may need to clean old lists in `/etc/apt/sources.list.d/`.
- **Port Conflict**: Default port is **8081** to avoid conflicts with common exporters.

## 📁 Project Structure

```
ansible-disaster-recovery/
├── inventories/          # Environment hosts & vars
├── roles/                # Modular logic (common, docker, application, etc.)
├── playbooks/            # Operations (backup, restore, disaster)
├── site.yml              # Main deployment entry point
├── Makefile              # Command shortcuts
└── docs/                 # Detailed manuals
```

## 📝 License
MIT - See [LICENSE](LICENSE) for details.