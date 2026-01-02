# Ansible Disaster Recovery Automation

[![Ansible](https://img.shields.io/badge/Ansible-2.9%2B-EE0000?style=flat&logo=ansible)](https://www.ansible.com/)
[![Docker](https://img.shields.io/badge/Docker-20.10%2B-2496ED?style=flat&logo=docker)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A production-ready Ansible project that automates complete disaster recovery for containerized applications with PostgreSQL database.

## 🎯 Project Overview

This project demonstrates enterprise-level DevOps practices for automated disaster recovery, including:

- **Zero-to-Production** infrastructure provisioning
- **Automated backups** of Docker volumes, databases, and configurations
- **One-command recovery** from catastrophic failures
- **Multi-environment support** (staging/production)
- **Idempotent operations** for safe re-execution
- **Comprehensive logging** and RTO metrics

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Ansible Controller                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Target Host(s)                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Docker     │  │ Application  │  │  PostgreSQL  │      │
│  │   Engine     │  │  Container   │  │  Container   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Backup Storage (Versioned)              │   │
│  │  • Docker Volumes  • Database Dumps  • Configs      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

- **Ansible Controller**: Ansible 2.9+ installed
- **Target Host**: Ubuntu 20.04+ / Debian 10+ / RHEL 8+
- **SSH Access**: Passwordless SSH configured or SSH key
- **Python**: Python 3.6+ on both controller and target
- **Minimum Resources**: 2 CPU, 4GB RAM, 20GB disk

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/sebas80sebas/ansible-disaster-recovery.git
cd ansible-disaster-recovery
```

### 2. Configure Inventory

You can test this project on a remote server or directly on your local machine.

#### For Local Testing (Your own PC)
Edit `inventories/staging/hosts` and set it to:
```ini
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
```

#### For Remote Testing
Edit the inventory file for your environment:

```bash
# For staging
vim inventories/staging/hosts
```

### 3. Test Connectivity
```bash
make ping ENV=staging
```

### 4. Configure Secrets (Optional)

```bash
# Create encrypted vault for sensitive data
ansible-vault create inventories/production/group_vars/vault.yml

# Add your secrets:
vault_db_password: "your-secure-password"
vault_backup_encryption_key: "your-encryption-key"
```

### 4. Deploy Complete Infrastructure

```bash
# Deploy to staging
ansible-playbook -i inventories/staging/hosts site.yml --ask-become-pass

# Deploy to production
ansible-playbook -i inventories/production/hosts site.yml --ask-vault-pass
```

## 🔄 Backup & Recovery Operations

### Manual Backup

```bash
ansible-playbook -i inventories/production/hosts playbooks/backup.yml
```

### Simulate Disaster & Recover

```bash
# Simulate total data loss
ansible-playbook -i inventories/production/hosts playbooks/simulate_disaster.yml

# Perform complete recovery
ansible-playbook -i inventories/production/hosts playbooks/restore.yml
```

### Verify Recovery

```bash
ansible-playbook -i inventories/production/hosts playbooks/verify.yml
```

## 📊 Recovery Time Objective (RTO)

Based on testing with standard infrastructure:

| Operation | Time | Description |
|-----------|------|-------------|
| Full Backup | 2-5 min | Volumes + DB dump + configs |
| Disaster Simulation | 30 sec | Stop and remove all containers/volumes |
| Full Recovery | 3-7 min | Restore + verify all components |
| **Total RTO** | **~10 min** | From disaster to fully operational |

*Times vary based on data size and network speed*

## 📁 Project Structure

```
ansible-disaster-recovery/
├── ansible.cfg                 # Ansible configuration
├── site.yml                    # Main playbook - full deployment
├── inventories/
│   ├── staging/
│   │   ├── hosts              # Staging inventory
│   │   └── group_vars/        # Staging variables
│   └── production/
│       ├── hosts              # Production inventory
│       └── group_vars/        # Production variables
├── playbooks/
│   ├── backup.yml             # Manual backup execution
│   ├── restore.yml            # Disaster recovery playbook
│   ├── simulate_disaster.yml  # Disaster simulation
│   └── verify.yml             # Post-recovery verification
├── roles/
│   ├── common/                # Base system setup
│   ├── docker/                # Docker installation
│   ├── application/           # App deployment
│   ├── backup/                # Backup automation
│   └── restore/               # Recovery procedures
├── docs/
│   ├── DEPLOYMENT.md          # Deployment guide
│   ├── DISASTER_RECOVERY.md   # DR procedures
│   └── TESTING.md             # Testing scenarios
└── README.md
```

## 🎓 Key Features

### 1. Idempotent Operations
All playbooks can be safely run multiple times without side effects.

### 2. Versioned Backups
Backups are timestamped and versioned for point-in-time recovery:
```
/opt/backups/
├── 2024-01-15_14-30-00/
│   ├── volumes/
│   ├── database/
│   └── configs/
└── 2024-01-15_20-00-00/
    ├── volumes/
    ├── database/
    └── configs/
```

### 3. Multi-Environment Support
Separate inventories and variables for staging and production.

### 4. Comprehensive Logging
All operations logged with timestamps and success/failure status.

### 5. Automated Verification
Post-recovery health checks ensure application integrity.

## 🔒 Security Best Practices

- ✅ Ansible Vault for sensitive data
- ✅ SSH key-based authentication
- ✅ Encrypted backup storage (optional)
- ✅ No hardcoded credentials
- ✅ Principle of least privilege

## 🛠️ Troubleshooting & Ubuntu 24.04 Tips

During the setup on modern Ubuntu systems (like 24.04 Noble), several adjustments were made to ensure compatibility:

### 1. Python & PEP 668
Modern Ubuntu versions block `pip install` outside of virtual environments. We modified the `common` role to use official Ubuntu packages (`python3-docker`, `python3-yaml`) instead of `pip`.

### 2. Docker Repository Conflict
If you encounter `Conflicting values set for option Signed-By`, ensure you remove old Docker list files:
```bash
sudo rm -f /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/docker.sources
```

### 3. Third-party Repository Errors
Ansible requires a clean `apt update`. If deployment fails at "Update apt cache", manually run `sudo apt update` and remove any failing PPAs or repositories in `/etc/apt/sources.list.d/`.

### 4. Docker Template Escaping
Docker uses `{{.Names}}` which conflicts with Ansible's Jinja2. We used `{% raw %} ... {% endraw %}` blocks in script templates to protect Docker's syntax.

## 🧪 Testing

Run the complete test suite:

```bash
# Deploy, backup, destroy, restore, verify
./scripts/full_dr_test.sh staging
```

See [TESTING.md](docs/TESTING.md) for detailed testing scenarios.

## 📚 Documentation

- [Deployment Guide](docs/DEPLOYMENT.md) - Step-by-step deployment
- [Disaster Recovery Procedures](docs/DISASTER_RECOVERY.md) - DR runbook
- [Testing Scenarios](docs/TESTING.md) - Test cases and validation

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

## 📝 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

## 👤 Author

**Your Name**
- GitHub: [@your-username](https://github.com/your-username)
- LinkedIn: [Your Profile](https://linkedin.com/in/your-profile)

## 🙏 Acknowledgments

- Ansible community for best practices
- Docker documentation for containerization patterns
- DevOps community for DR strategies

---

⭐ **Star this repository** if you find it helpful for your DevOps journey!
