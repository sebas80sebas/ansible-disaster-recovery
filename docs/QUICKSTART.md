# Quick Start Guide

Get up and running with disaster recovery in 5 minutes!

## Prerequisites

- Ansible 2.10+ installed on your controller
- Ubuntu 20.04/22.04/24.04 target host
- SSH access or local execution permissions

## 5-Minute Setup

### 1. Clone and Configure (1 minute)

```bash
git clone https://github.com/your-username/ansible-disaster-recovery.git
cd ansible-disaster-recovery

# To test on your own computer (Localhost):
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

### 2. Test Connectivity (30 seconds)

```bash
make ping ENV=staging
```

### 3. Deploy Everything (3 minutes)

```bash
# Use --ask-become-pass to provide your sudo password
ansible-playbook -i inventories/staging/hosts site.yml --ask-become-pass
```

> **Note for Ubuntu 24.04**: If you see "externally-managed-environment" errors, the project has already been updated to use `apt` packages for Docker libraries. No manual fix is required.

### 4. Verify (30 seconds)

```bash
# Check application
curl http://YOUR_HOST_IP:8080/health

# Or open in browser
firefox http://YOUR_HOST_IP:8080
```

## Test Disaster Recovery

### Full DR Test (10 minutes)

```bash
# Run automated test
./scripts/full_dr_test.sh inventories/staging/hosts
```

This will:
1. ✓ Deploy infrastructure
2. ✓ Create test data
3. ✓ Create backup
4. ✓ Simulate disaster
5. ✓ Restore everything
6. ✓ Verify recovery

### Manual DR Test

```bash
# 1. Create backup
make backup

# 2. Simulate disaster
make disaster

# 3. Restore
make restore

# 4. Verify
make verify
```

## Using Make Commands

```bash
make help              # Show all commands
make deploy           # Deploy infrastructure
make backup           # Create backup
make restore          # Restore from backup
make verify           # Verify application
make test             # Run complete DR test
make status           # Check backup status
```

## Common Operations

### Create Manual Backup

```bash
ansible-playbook -i inventories/staging/hosts playbooks/backup.yml
```

### Check Backup Status

```bash
ansible -i inventories/staging/hosts backup_servers \
  -a "/opt/backup_scripts/check_backup_status.sh"
```

### View Application Logs

```bash
ansible -i inventories/staging/hosts app_servers \
  -a "docker logs todoapp_app"
```

## Troubleshooting

### Can't Connect?

```bash
# Test SSH
ssh ubuntu@YOUR_HOST_IP

# If fails, copy SSH key
ssh-copy-id ubuntu@YOUR_HOST_IP
```

### Application Not Starting?

```bash
# Check containers
ansible -i inventories/staging/hosts all -a "docker ps -a"

# Check logs
ansible -i inventories/staging/hosts all -a "docker logs todoapp_app"
```

### Backup Failed?

```bash
# Check disk space
ansible -i inventories/staging/hosts all -a "df -h"

# Check backup logs
ansible -i inventories/staging/hosts all -a "cat /opt/backups/logs/backup.log"
```

## Next Steps

1. **Read Full Documentation**: See [README.md](README.md)
2. **Production Setup**: See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)
3. **DR Procedures**: See [docs/DISASTER_RECOVERY.md](docs/DISASTER_RECOVERY.md)
4. **Testing Guide**: See [docs/TESTING.md](docs/TESTING.md)

## Need Help?

Check the troubleshooting sections in:
- [DEPLOYMENT.md](docs/DEPLOYMENT.md#troubleshooting)
- [DISASTER_RECOVERY.md](docs/DISASTER_RECOVERY.md#troubleshooting-recovery)

Happy automating! 🚀
