# Resilience Taskboard - Ansible Disaster Recovery

[![Ansible](https://img.shields.io/badge/Ansible-2.10%2B-EE0000?style=flat&logo=ansible)](https://www.ansible.com/)
[![Docker](https://img.shields.io/badge/Docker-24%2B-2496ED?style=flat&logo=docker)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A production-ready Ansible project that automates disaster recovery for the **Resilience Taskboard**, a containerized Flask application with PostgreSQL storage.

## Project Overview

This project demonstrates enterprise-level DevOps practices for automated backup and recovery, including:

- **Zero-to-Production** infrastructure provisioning.
- **Modern UI**: Redesigned frontend using Bootstrap 5.
- **Multi-layer Backups**: Automation for Docker volumes, databases, and configs.
- **One-command Recovery**: Seamless restoration from catastrophic failures.
- **Ubuntu 24.04 Ready**: Fully compliant with modern security and Python standards (PEP 668).

## Quick Start

### 1. Prerequisites
- **OS**: Linux (Ubuntu 24.04 LTS recommended)
- **Tools**: Ansible, Make, Git
- **User**: Sudo privileges required

### 2. Deploy Infrastructure
You can use the provided Makefile for convenience. It handles the deployment to your local machine (staging) by default.

```bash
# Full deployment (installs Docker, App, and Backup scripts)
make deploy
```

Or manually with Ansible:
```bash
ansible-playbook -i inventories/staging/hosts site.yml --ask-become-pass
```

### 3. Verify Deployment
Access the application at: **http://localhost:8081**

### 4. Disaster Recovery Workflow
Follow these steps to test the resilience of the system:

1.  **Create Data**: Add some tasks in the web UI.
2.  **Backup**: Create a secure restore point.
    ```bash
    make backup
    ```
    **Alternative Ansible Command:**
    ```bash
    ansible-playbook -i inventories/staging/hosts playbooks/backup.yml --ask-become-pass
    ```

3.  **Simulate Disaster**: (WARNING: Destructive!) Stops containers and deletes volumes.
    ```bash
    make disaster
    # Type 'destroy' when prompted
    ```
    **Alternative Ansible Command:**
    ```bash
    ansible-playbook -i inventories/staging/hosts playbooks/simulate_disaster.yml --ask-become-pass
    ```

4.  **Restore**: Recover everything from the latest backup.
    ```bash
    make restore
    ```
    **Alternative Ansible Command:**
    ```bash
    ansible-playbook -i inventories/staging/hosts playbooks/restore.yml --ask-become-pass
    ```

5.  **Verify**: Check the URL again. Your data should be back.

## Troubleshooting

### Common Issues on Ubuntu 24.04

#### 1. PPA Repository Errors (apt update fails)
If `make deploy` fails during the "Update apt cache" task with errors about unsafe repositories (e.g., `team-xbmc/ppa`), you need to remove the conflicting PPA from your system:
```bash
sudo add-apt-repository --remove ppa:team-xbmc/ppa
# Or manually check /etc/apt/sources.list.d/
```

#### 2. Docker Compose Errors
The project is optimized for **Docker Compose v2** (Plugin). 
- If you see `ModuleNotFoundError: No module named 'compose'`, it means Ansible is trying to use the legacy Python module. 
- **Fix**: We have updated the playbooks to use `shell: docker compose` commands directly, which is more robust. Ensure you have the `docker-compose-plugin` installed (handled automatically by the `docker` role).

#### 3. "Force" Parameter Error
If you encounter `Unsupported parameters for (docker_volume) module: force`, it is because recent Ansible versions deprecated this parameter.
- **Fix**: The current `simulate_disaster.yml` playbook has been patched to remove this parameter. Update your repo if you see this.

#### 4. Makefile "read" Error
If `make restore` fails with `read: arg count`, it's because `/bin/sh` (dash) doesn't support `read -p`.
- **Fix**: The Makefile now explicitly uses `SHELL := /bin/bash` to ensure compatibility.

## Project Structure

```
ansible-disaster-recovery/
├── inventories/          # Environment hosts & vars
├── roles/                # Modular logic (common, docker, application, etc.)
├── playbooks/            # Operations (backup, restore, disaster)
├── site.yml              # Main deployment entry point
├── Makefile              # Command shortcuts
└── docs/                 # Detailed manuals
```

## License
MIT - See [LICENSE](LICENSE) for details.