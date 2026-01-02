# Deployment Guide

This guide provides step-by-step instructions for deploying the complete disaster recovery infrastructure.

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
- **Ansible**: Version 2.9 or higher
- **Python**: Version 3.6 or higher
- **SSH Client**: OpenSSH or compatible

### Target Host(s)

- **Operating System**: Ubuntu 20.04+, Debian 10+, or RHEL 8+
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
  - `8080`: Application HTTP
  - `5432`: PostgreSQL (only if external access needed)

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
sudo apt install ansible python3-pip
pip3 install docker docker-compose
```

#### On macOS:
```bash
brew install ansible
pip3 install docker docker-compose
```

#### Verify Installation:
```bash
ansible --version
# Should show Ansible 2.9+
```

### 3. Configure SSH Access

#### Generate SSH Key (if needed):
```bash
ssh-keygen -t ed25519 -C "ansible-automation"
```

#### Copy SSH Key to Target Host:
```bash
ssh-copy-id ubuntu@<target-host-ip>
```

#### Test SSH Connection:
```bash
ssh ubuntu@<target-host-ip>
```

## Configuration

### 1. Configure Inventory

Edit the appropriate inventory file:

**For Staging:**
```bash
vim inventories/staging/hosts
```

Update with your target host IP:
```ini
[app_servers]
staging-app-01 ansible_host=192.168.1.10 ansible_user=ubuntu

[db_servers]
staging-app-01

[backup_servers]
staging-app-01
```

**For Production:**
```bash
vim inventories/production/hosts
```

### 2. Configure Variables

Edit environment-specific variables:

**Staging:**
```bash
vim inventories/staging/group_vars/all.yml
```

**Production:**
```bash
vim inventories/production/group_vars/all.yml
```

Key variables to configure:
- `app_name`: Application name
- `app_port`: Application port
- `db_password`: Database password (use vault for production!)
- `backup_schedule`: Cron schedule for backups
- `backup_retention_days`: Number of days to keep backups

### 3. Configure Secrets (Production Only)

For production, use Ansible Vault:

```bash
# Create vault file
ansible-vault create inventories/production/group_vars/vault.yml
```

Add your secrets:
```yaml
---
vault_db_password: "your-secure-password-here"
vault_backup_encryption_key: "your-encryption-key"
```

Update `all.yml` to reference vault variables:
```yaml
db_password: "{{ vault_db_password }}"
```

### 4. Test Connectivity

```bash
# Test staging
ansible -i inventories/staging/hosts all -m ping

# Test production
ansible -i inventories/production/hosts all -m ping --ask-vault-pass
```

Expected output:
```
staging-app-01 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## Deployment

### Full Infrastructure Deployment

#### Staging Environment:
```bash
ansible-playbook -i inventories/staging/hosts site.yml
```

#### Production Environment:
```bash
ansible-playbook -i inventories/production/hosts site.yml --ask-vault-pass
```

### Deployment Process Overview

The deployment executes the following roles in order:

1. **Common** (~2 minutes)
   - Updates system packages
   - Installs essential tools
   - Configures system settings

2. **Docker** (~3 minutes)
   - Installs Docker CE
   - Configures Docker daemon
   - Installs Docker Compose

3. **Application** (~5 minutes)
   - Creates application structure
   - Builds Docker images
   - Deploys containers
   - Initializes database

4. **Backup** (~3 minutes)
   - Installs backup scripts
   - Configures cron jobs
   - Performs initial backup

**Total Deployment Time**: ~15 minutes

### Deployment Output

You should see output similar to:
```
PLAY [Complete Infrastructure Deployment] **************************************

TASK [Display deployment information] *****************************************
ok: [staging-app-01] => {
    "msg": [
        "==========================================",
        "Deploying to environment: staging",
        "Target host: staging-app-01",
        "==========================================
    ]
}

TASK [common : Update apt cache] **********************************************
changed: [staging-app-01]

...

PLAY RECAP ********************************************************************
staging-app-01             : ok=47   changed=28   unreachable=0    failed=0
```

## Verification

### 1. Check Application Status

```bash
# Via Ansible
ansible-playbook -i inventories/staging/hosts playbooks/verify.yml

# Manual check
curl http://<target-host-ip>:8080/health
```

Expected response:
```json
{
  "status": "healthy",
  "database": "connected",
  "timestamp": "2024-01-15T10:30:00"
}
```

### 2. Access Application

Open browser to: `http://<target-host-ip>:8080`

You should see the Todo application interface.

### 3. Verify Backup System

```bash
# Check backup status
ansible -i inventories/staging/hosts backup_servers \
  -a "/opt/backup_scripts/check_backup_status.sh"
```

### 4. Test Manual Backup

```bash
ansible-playbook -i inventories/staging/hosts playbooks/backup.yml
```

## Deployment Options

### Deploy Specific Roles Only

```bash
# Only install Docker
ansible-playbook -i inventories/staging/hosts site.yml --tags docker

# Only deploy application
ansible-playbook -i inventories/staging/hosts site.yml --tags application

# Only configure backups
ansible-playbook -i inventories/staging/hosts site.yml --tags backup
```

### Skip Specific Roles

```bash
# Skip backup configuration
ansible-playbook -i inventories/staging/hosts site.yml --skip-tags backup
```

### Dry Run (Check Mode)

```bash
# See what would change without making changes
ansible-playbook -i inventories/staging/hosts site.yml --check
```

### Verbose Output

```bash
# Increase verbosity for debugging
ansible-playbook -i inventories/staging/hosts site.yml -v    # verbose
ansible-playbook -i inventories/staging/hosts site.yml -vv   # more verbose
ansible-playbook -i inventories/staging/hosts site.yml -vvv  # very verbose
```

## Troubleshooting

### Common Issues

#### 1. SSH Connection Failed

**Error**: `UNREACHABLE! => {"changed": false, "msg": "Failed to connect"}`

**Solutions**:
- Verify SSH key is configured: `ssh ubuntu@<target-host-ip>`
- Check firewall allows SSH: `sudo ufw status`
- Verify correct user in inventory file

#### 2. Sudo Password Required

**Error**: `FAILED! => {"msg": "Missing sudo password"}`

**Solutions**:
- Add `--ask-become-pass` flag
- Configure passwordless sudo on target
- Update ansible.cfg: `become_ask_pass = False`

#### 3. Docker Installation Failed

**Error**: Docker package not found

**Solutions**:
- Ensure target OS is supported (Ubuntu 20.04+)
- Check internet connectivity
- Manually update apt: `sudo apt update`

#### 4. Application Not Accessible

**Error**: Cannot connect to application

**Solutions**:
```bash
# Check containers are running
ansible -i inventories/staging/hosts app_servers \
  -a "docker ps"

# Check application logs
ansible -i inventories/staging/hosts app_servers \
  -a "docker logs todoapp_app"

# Verify ports are open
ansible -i inventories/staging/hosts app_servers \
  -a "ss -tlnp | grep 8080"
```

#### 5. Backup Failed

**Error**: Backup script failed

**Solutions**:
```bash
# Check backup logs
ansible -i inventories/staging/hosts backup_servers \
  -a "cat /opt/backups/logs/backup.log"

# Verify disk space
ansible -i inventories/staging/hosts backup_servers \
  -a "df -h /opt/backups"

# Run backup manually
ansible -i inventories/staging/hosts backup_servers \
  -a "/opt/backup_scripts/backup.sh"
```

### Getting Help

If you encounter issues:

1. Check logs: `/var/log/ansible.log`
2. Run with verbose output: `-vvv`
3. Review role-specific logs in `/var/log/<app_name>/`
4. Verify all prerequisites are met

## Next Steps

After successful deployment:

1. **Test Disaster Recovery**: See [DISASTER_RECOVERY.md](DISASTER_RECOVERY.md)
2. **Configure Monitoring**: Setup monitoring for production
3. **Schedule Regular Tests**: Test recovery procedures monthly
4. **Update Documentation**: Document any customizations

## Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
