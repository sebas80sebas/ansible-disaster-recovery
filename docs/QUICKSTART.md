# Quick Start Guide - Resilience Taskboard

Get up and running with automated disaster recovery in minutes!

## Prerequisites

- **Ansible 2.10+**
- **Ubuntu 20.04 - 24.04**
- **Sudo privileges**

## 1. Setup Local Environment

Most users start by testing on their local machine. Configure your inventory:

```bash
# Edit inventories/staging/hosts to use localhost
cat <<EOF > inventories/staging/hosts
[app_servers]
localhost ansible_connection=local

[db_servers]
localhost ansible_connection=local

[backup_servers]
localhost ansible_connection=local

[staging:children]
app_servers
db_servers
backup_servers

[staging:vars]
env_name=staging
ansible_python_interpreter=/usr/bin/python3
EOF
```

## 2. Deploy the Infrastructure

Run the main playbook. You will be prompted for your sudo password.

```bash
ansible-playbook -i inventories/staging/hosts site.yml --ask-become-pass
```

Once finished, open your browser at **http://localhost:8081**.

## 3. The Disaster Recovery Cycle

Follow these steps to experience the automation:

### Step A: Create Data
Add some tasks in the UI (e.g., "Critical Task 1", "Backup verification").

### Step B: Create a Backup
```bash
make backup ENV=staging
```
This stores your database and files in `/opt/backups/`.

### Step C: Simulate Disaster
```bash
make disaster ENV=staging
```
**Warning**: This deletes your containers and data volumes. The web UI will stop working.

### Step D: Restore Everything
```bash
make restore ENV=staging
```
Refresh the browser. Your tasks are back!

## Useful Commands

- `make logs`: View application behavior.
- `make verify`: Automated health check.
- `make clean`: Remove temporary Ansible files.

Happy automating!