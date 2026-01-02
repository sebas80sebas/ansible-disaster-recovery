# Testing Guide

This guide covers all testing scenarios for the disaster recovery system.

## Table of Contents

1. [Quick Testing](#quick-testing)
2. [Component Testing](#component-testing)
3. [Integration Testing](#integration-testing)
4. [Performance Testing](#performance-testing)
5. [Automated Testing](#automated-testing)

## Quick Testing

### 1. Syntax Check

Verify Ansible playbook syntax:

```bash
# Check main playbook
ansible-playbook site.yml --syntax-check

# Check all playbooks
for playbook in playbooks/*.yml; do
    ansible-playbook $playbook --syntax-check
done
```

### 2. Dry Run

Test without making changes:

```bash
ansible-playbook -i inventories/staging/hosts site.yml --check
```

### 3. Single Host Test

Test on one host before full deployment:

```bash
ansible-playbook -i inventories/staging/hosts site.yml --limit staging-app-01
```

## Component Testing

### Test Common Role

```bash
ansible-playbook -i inventories/staging/hosts site.yml --tags common
```

**Verify**:
- Essential packages installed
- Directories created
- System configured correctly

### Test Docker Role

```bash
ansible-playbook -i inventories/staging/hosts site.yml --tags docker
```

**Verify**:
```bash
ansible -i inventories/staging/hosts all -m shell -a "docker --version"
ansible -i inventories/staging/hosts all -m shell -a "docker-compose --version"
```

### Test Application Role

```bash
ansible-playbook -i inventories/staging/hosts site.yml --tags application
```

**Verify**:
```bash
# Check containers
ansible -i inventories/staging/hosts all -m shell -a "docker ps"

# Check application
curl http://<host-ip>:8080/health

# Check database
curl http://<host-ip>:8080/api/todos
```

### Test Backup Role

```bash
ansible-playbook -i inventories/staging/hosts site.yml --tags backup
```

**Verify**:
```bash
# Check backup scripts exist
ansible -i inventories/staging/hosts all -m shell \
  -a "ls -la /opt/backup_scripts/"

# Check backup was created
ansible -i inventories/staging/hosts all -m shell \
  -a "ls -la /opt/backups/latest"

# Verify backup contents
ansible -i inventories/staging/hosts all -m shell \
  -a "/opt/backup_scripts/verify_backup.sh"
```

## Integration Testing

### Full Deployment Test

Test complete deployment from scratch:

```bash
# 1. Deploy everything
ansible-playbook -i inventories/staging/hosts site.yml

# 2. Verify deployment
ansible-playbook -i inventories/staging/hosts playbooks/verify.yml

# 3. Check all services
curl http://<host-ip>:8080/health
curl http://<host-ip>:8080/api/todos
```

### Backup and Restore Test

Test the complete backup and restore cycle:

```bash
# 1. Create some test data
for i in {1..10}; do
    curl -X POST http://<host-ip>:8080/api/todos \
        -H "Content-Type: application/json" \
        -d "{\"title\": \"Test todo $i\"}"
done

# 2. Create backup
ansible-playbook -i inventories/staging/hosts playbooks/backup.yml

# 3. Simulate disaster
ansible-playbook -i inventories/staging/hosts playbooks/simulate_disaster.yml

# 4. Restore
time ansible-playbook -i inventories/staging/hosts playbooks/restore.yml --skip-tags confirm

# 5. Verify
ansible-playbook -i inventories/staging/hosts playbooks/verify.yml
```

### Idempotency Test

Verify playbooks can be run multiple times safely:

```bash
# Run twice and compare results
ansible-playbook -i inventories/staging/hosts site.yml > run1.log
ansible-playbook -i inventories/staging/hosts site.yml > run2.log

# Second run should show mostly "ok" and no "changed"
grep "changed=" run2.log
```

## Performance Testing

### Backup Performance

Test backup performance with different data sizes:

```bash
#!/bin/bash
# backup_performance_test.sh

INVENTORY="inventories/staging/hosts"

# Create test data of various sizes
create_test_data() {
    local size=$1
    echo "Creating ${size} test records..."
    for i in $(seq 1 $size); do
        curl -sf -X POST http://192.168.1.10:8080/api/todos \
            -H "Content-Type: application/json" \
            -d "{\"title\": \"Performance test ${i}\"}" > /dev/null
    done
}

# Test backup
test_backup() {
    local data_size=$1
    echo "Testing backup with ${data_size} records..."
    
    START=$(date +%s)
    ansible-playbook -i $INVENTORY playbooks/backup.yml > /dev/null 2>&1
    END=$(date +%s)
    DURATION=$((END - START))
    
    BACKUP_SIZE=$(ansible -i $INVENTORY backup_servers \
        -m shell -a "du -sh /opt/backups/latest | cut -f1" | grep -v "^staging")
    
    echo "Data size: ${data_size} records"
    echo "Backup duration: ${DURATION} seconds"
    echo "Backup size: ${BACKUP_SIZE}"
    echo "---"
}

# Run tests
for size in 100 500 1000 5000; do
    create_test_data $size
    test_backup $size
    
    # Clean up
    ansible-playbook -i $INVENTORY playbooks/simulate_disaster.yml \
        --extra-vars '{"confirmation":{"user_input":"destroy"}}' > /dev/null 2>&1
    ansible-playbook -i $INVENTORY site.yml > /dev/null 2>&1
done
```

### Recovery Performance

Test recovery time with different scenarios:

```bash
#!/bin/bash
# recovery_performance_test.sh

INVENTORY="inventories/staging/hosts"

test_recovery() {
    local scenario=$1
    echo "Testing recovery scenario: ${scenario}"
    
    # Simulate disaster
    ansible-playbook -i $INVENTORY playbooks/simulate_disaster.yml \
        --extra-vars '{"confirmation":{"user_input":"destroy"}}' > /dev/null 2>&1
    
    # Time recovery
    START=$(date +%s)
    ansible-playbook -i $INVENTORY playbooks/restore.yml --skip-tags confirm > /dev/null 2>&1
    END=$(date +%s)
    DURATION=$((END - START))
    
    echo "Recovery duration: ${DURATION} seconds ($(echo "scale=2; ${DURATION}/60" | bc) minutes)"
    echo "---"
}

# Test scenarios
test_recovery "Small database (< 100MB)"
test_recovery "Medium database (< 500MB)"
test_recovery "Large database (< 2GB)"
```

### Load Testing

Test application performance after recovery:

```bash
# Install Apache Bench if not available
sudo apt-get install apache2-utils

# Test load
ab -n 1000 -c 10 http://<host-ip>:8080/health

# Test API endpoint
ab -n 500 -c 5 -p todo.json -T application/json http://<host-ip>:8080/api/todos

# todo.json content:
# {"title": "Load test todo"}
```

## Automated Testing

### Continuous Integration Test

Example GitHub Actions workflow:

```yaml
# .github/workflows/test.yml
name: DR Testing

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Install Ansible
      run: |
        sudo apt update
        sudo apt install -y ansible
        pip install docker docker-compose
    
    - name: Syntax check
      run: |
        for playbook in site.yml playbooks/*.yml; do
          ansible-playbook $playbook --syntax-check
        done
    
    - name: Ansible lint
      run: |
        pip install ansible-lint
        ansible-lint site.yml
```

### Automated Daily Test

Schedule daily DR tests:

```bash
# Add to crontab
0 2 * * * /opt/scripts/full_dr_test.sh inventories/staging/hosts >> /var/log/dr_tests.log 2>&1
```

### Test Report Generation

Generate comprehensive test reports:

```bash
#!/bin/bash
# generate_test_report.sh

REPORT_FILE="dr_test_report_$(date +%Y%m%d_%H%M%S).html"

cat > $REPORT_FILE <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>DR Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        .pass { color: green; }
        .fail { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
    </style>
</head>
<body>
    <h1>Disaster Recovery Test Report</h1>
    <p>Generated: $(date)</p>
    
    <h2>Test Results</h2>
    <table>
        <tr>
            <th>Test</th>
            <th>Status</th>
            <th>Duration</th>
        </tr>
        <!-- Add test results here -->
    </table>
</body>
</html>
EOF

echo "Report generated: $REPORT_FILE"
```

## Test Checklist

Before production deployment:

- [ ] All syntax checks pass
- [ ] Dry run completes without errors
- [ ] Full deployment successful
- [ ] Backup creation works
- [ ] Disaster simulation works
- [ ] Recovery completes within RTO
- [ ] Data integrity verified
- [ ] Application functional after recovery
- [ ] Idempotency verified
- [ ] Performance acceptable
- [ ] Documentation updated

## Troubleshooting Tests

### Test Failures

If tests fail:

1. **Check logs**:
   ```bash
   tail -f ansible.log
   ```

2. **Increase verbosity**:
   ```bash
   ansible-playbook -vvv ...
   ```

3. **Check specific host**:
   ```bash
   ansible -i inventories/staging/hosts all -m ping
   ```

4. **Verify connectivity**:
   ```bash
   ansible -i inventories/staging/hosts all -m shell -a "uptime"
   ```

### Common Issues

1. **SSH Connection Failed**
   - Verify SSH key
   - Check firewall
   - Verify host IP

2. **Backup Failed**
   - Check disk space
   - Verify container is running
   - Check backup script permissions

3. **Recovery Timeout**
   - Increase timeout values
   - Check network speed
   - Verify backup integrity

## Best Practices

1. **Test Regularly**: Run DR tests at least monthly
2. **Document Results**: Keep test reports for compliance
3. **Measure RTO**: Track recovery times over time
4. **Update Tests**: Add tests for new features
5. **Automate**: Use CI/CD for automated testing

## Related Documentation

- [Deployment Guide](DEPLOYMENT.md)
- [Disaster Recovery Guide](DISASTER_RECOVERY.md)
- [README](../README.md)
