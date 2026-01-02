# Deployment Guide - Resilience Taskboard

This guide provides step-by-step instructions for deploying the complete disaster recovery infrastructure for the Resilience Taskboard application.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Configuration](#configuration)
4. [Deployment](#deployment)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### Ansible Controller

- **Operating System**: Linux, macOS, or WSL2
- **Ansible**: Version 2.10 or higher
- **Python**: Version 3.8 or higher
- **SSH Client**: OpenSSH or compatible

### Target Host(s)

- **Operating System**: Ubuntu 20.04+, Debian 10+, or RHEL 8+ (Optimized for Ubuntu 24.04 Noble)
- **Minimum Resources**:
  - 2 CPU cores
  - 4 GB RAM
  - 20 GB disk space
- **Network**: SSH access (port 22)
- **Privileges**: Sudo access

### Network Requirements

- SSH connectivity from Ansible controller to target hosts
- Outbound internet access for package downloads
- Open ports:
  - `8081`: Resilience Taskboard HTTP (Changed from 8080 to avoid conflicts)
  - `5432`: PostgreSQL (Internal only by default)

## Initial Setup

### 1. Clone Repository

```bash
git clone https://github.com/your-username/ansible-disaster-recovery.git
cd ansible-disaster-recovery
```

### 2. Install Ansible

#### On Ubuntu/Debian:
```bash
sudo apt update
sudo apt install -y ansible
```

> **Note for Ubuntu 24.04**: We avoid `pip install` for Docker libraries to comply with PEP 668. The automation handles this using `python3-docker` and `python3-yaml` apt packages.

#### Verify Installation:
```bash
ansible --version
# Should show Ansible 2.10+
```

### 3. Configure SSH Access (For Remote Hosts)

#### Generate SSH Key:
```bash
ssh-keygen -t ed25519 -C "ansible-automation"
```

#### Copy SSH Key to Target Host:
```bash
ssh-copy-id ubuntu@<target-host-ip>
```

## Configuration

### 1. Configure Inventory

Edit the appropriate inventory file:

**For Local Testing (Recommended for first-time users):**
Edit `inventories/staging/hosts`:
```ini
[app_servers]
localhost ansible_connection=local

[db_servers]
localhost ansible_connection=local

[backup_servers]
localhost ansible_connection=local
```

**For Remote Staging:**
Update `inventories/staging/hosts` with your target host IP.

### 2. Configure Variables

Edit `inventories/staging/group_vars/all.yml`:
- `app_port`: 8081
- `db_password`: Set your secure password
- `backup_schedule`: "0 * * * *" (default: hourly)

## Deployment

### Full Infrastructure Deployment

```bash
# Use --ask-become-pass to provide your sudo password
ansible-playbook -i inventories/staging/hosts site.yml --ask-become-pass
```

### Deployment Process Overview

The deployment executes the following roles in order:

1. **Common**: Updates packages, installs `python3-docker`, configures NTP and logrotate.
2. **Docker**: Installs Docker Engine and the **Docker Compose Plugin** (v2).
3. **Application**: Deploys the **Resilience Taskboard** (Flask + PostgreSQL) on port 8081.
4. **Backup**: Installs automated backup and retention scripts in `/opt/backup_scripts/`.

## Verification

### 1. Check Application Status

```bash
# Manual check
curl http://localhost:8081/health
```

Expected response:
```json
{
  "status": "healthy",
  "database": "connected",
  "timestamp": "2026-01-02T..."
}
```

### 2. Access UI

Open browser to: `http://localhost:8081`

### 3. Test Manual Backup

```bash
make backup ENV=staging
```

## Troubleshooting

### Common Ubuntu 24.04 Issues

#### 1. APT Repository Conflict
If you see `Conflicting values set for option Signed-By`, run:
```bash
sudo rm -f /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/docker.sources
sudo apt update
```

#### 2. Docker API Version Mismatch
If `docker-compose` fails, ensure you are using the plugin via `docker compose`. The automation has been updated to use the plugin by default.

#### 3. Infinite Loading Spinner
If the UI shows a loading spinner forever:
- Check if the database table exists:
  `sudo docker exec -it todoapp_db psql -U todouser -d tododb -c "\dt"`
- Verify network connectivity between containers.

### Getting Help

If you encounter issues, run with verbose output:
```bash
ansible-playbook -i inventories/staging/hosts site.yml --ask-become-pass -vvv
```