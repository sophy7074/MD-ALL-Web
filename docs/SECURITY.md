# MD-ALL Security & HIPAA Compliance Guide

## ⚠️ CRITICAL SECURITY NOTICE

MD-ALL handles genomic and potentially identifiable patient data. **Improper deployment can result in:**
- HIPAA violations and fines ($100 - $50,000 per violation)
- Data breaches exposing patient information
- Loss of institutional research privileges
- Legal liability

**This guide is MANDATORY for clinical/PHI data deployments.**

---

## Table of Contents
1. [HIPAA Compliance Requirements](#hipaa-compliance-requirements)
2. [Infrastructure Security](#infrastructure-security)
3. [Application Security](#application-security)
4. [Data Security](#data-security)
5. [Access Control](#access-control)
6. [Audit & Monitoring](#audit--monitoring)
7. [Incident Response](#incident-response)
8. [Security Checklist](#security-checklist)

---

## HIPAA Compliance Requirements

### What is PHI in MD-ALL Context?

**Protected Health Information (PHI) includes:**
- Patient identifiers (names, MRNs, dates of birth)
- Sample identifiers linked to patients
- Clinical metadata (diagnosis dates, treatment info)
- Genomic data that could identify individuals

**De-identified Data:**
- Anonymous sample IDs with no linkage to patients
- Aggregated statistics
- Published datasets (with proper consent)

### When HIPAA Applies

HIPAA compliance is REQUIRED if:
1. ✅ You are a covered entity (hospital, clinic, research institution receiving federal funds)
2. ✅ You handle PHI as defined above
3. ✅ Your application creates, receives, maintains, or transmits PHI

### Technical Safeguards (§164.312)

#### Access Control (§164.312(a)(1))
- [ ] Unique user IDs for all users
- [ ] Emergency access procedures
- [ ] Automatic logoff after inactivity
- [ ] Encryption and decryption mechanisms

#### Audit Controls (§164.312(b))
- [ ] Record and examine activity in systems with PHI
- [ ] Log all access, modifications, and deletions
- [ ] Retain logs for minimum 6 years

#### Integrity (§164.312(c)(1))
- [ ] Protect PHI from improper alteration or destruction
- [ ] Implement checksums/digital signatures

#### Transmission Security (§164.312(e)(1))
- [ ] Encrypt PHI during transmission
- [ ] Use TLS 1.2+ for all connections
- [ ] VPN for remote access

---

## Infrastructure Security

### 1. Server Hardening

#### Operating System Configuration
```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Enable automatic security updates
sudo apt-get install unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Disable root login
sudo passwd -l root

# Configure SSH (edit /etc/ssh/sshd_config)
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers admin_user1 admin_user2
ClientAliveInterval 300
ClientAliveCountMax 2

# Restart SSH
sudo systemctl restart sshd
```

#### Firewall Configuration
```bash
# UFW (Ubuntu)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from INSTITUTIONAL_IP_RANGE to any port 22
sudo ufw allow from INSTITUTIONAL_IP_RANGE to any port 443
sudo ufw enable

# Log all blocked attempts
sudo ufw logging on
```

#### SELinux/AppArmor
```bash
# Enable SELinux (CentOS/RHEL)
sudo setenforce 1
sudo vi /etc/selinux/config
# Set: SELINUX=enforcing

# Or AppArmor (Ubuntu)
sudo systemctl enable apparmor
sudo systemctl start apparmor
```

### 2. Network Security

#### Network Segmentation
```
Internet
    |
Institutional Firewall
    |
DMZ (Jump Host/VPN)
    |
Internal Network Firewall
    |
MD-ALL Server (Isolated VLAN)
```

#### VPN Configuration (OpenVPN Example)
```bash
# Install OpenVPN
sudo apt-get install openvpn

# Configure client authentication
# Require: Certificate + Password + 2FA
```

#### Intrusion Detection (Fail2ban)
```bash
# Install fail2ban
sudo apt-get install fail2ban

# Configure (edit /etc/fail2ban/jail.local)
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /logs/nginx-error.log
maxretry = 10
findtime = 600
bantime = 7200

sudo systemctl restart fail2ban
```

---

## Application Security

### 1. Authentication & Authorization

#### LDAP Integration (Recommended for Institutions)

**Configuration:**
```yaml
# config/auth.yml
auth:
  type: ldap
  ldap:
    host: ldaps://ldap.institution.edu:636
    base_dn: ou=users,dc=institution,dc=edu
    bind_dn: cn=mdall-service,ou=services,dc=institution,dc=edu
    bind_password: ${LDAP_PASSWORD}
    user_filter: (&(objectClass=person)(uid={username}))
    group_filter: (member={dn})
    required_group: cn=mdall-users,ou=groups,dc=institution,dc=edu
  session:
    timeout: 3600  # 1 hour
    require_reauth_for_sensitive: true
```

#### Single Sign-On (SSO) Integration

**SAML 2.0 Example:**
```R
# modules/auth_saml.R
library(saml)

auth_saml <- function(assertion) {
  # Validate SAML assertion
  if (!validate_assertion(assertion)) {
    return(NULL)
  }
  
  # Extract attributes
  user <- list(
    username = assertion$NameID,
    email = assertion$attributes$email,
    groups = assertion$attributes$groups,
    institution = assertion$attributes$institution
  )
  
  # Log authentication
  log_audit("AUTH_SUCCESS", user$username)
  
  return(user)
}
```

#### Multi-Factor Authentication (MFA)

```R
# modules/auth_mfa.R
library(googleAuthenticator)

enable_mfa <- function(user_id) {
  # Generate secret
  secret <- generate_secret()
  
  # Store encrypted secret
  store_secret(user_id, encrypt(secret))
  
  # Return QR code
  return(qr_code_url(user_id, secret))
}

verify_mfa <- function(user_id, token) {
  secret <- decrypt(get_secret(user_id))
  return(verify_token(secret, token))
}
```

### 2. Session Security

```R
# app/global.R
options(
  shiny.maxRequestSize = 500*1024^2,  # 500 MB
  shiny.sanitize.errors = TRUE,        # Hide stack traces
  shiny.port = 3838,
  shiny.host = "127.0.0.1"            # Bind to localhost only
)

# Session configuration
session_config <- list(
  timeout = 3600,          # 1 hour idle timeout
  max_lifetime = 28800,    # 8 hour maximum session
  regenerate_id = TRUE,    # Regenerate session ID on auth
  secure_cookie = TRUE,    # HTTPS only
  httponly_cookie = TRUE,  # Not accessible via JavaScript
  samesite = "Strict"      # CSRF protection
)
```

### 3. Input Validation

```R
# modules/validation.R
validate_sample_id <- function(id) {
  # Only alphanumeric and underscores
  if (!grepl("^[a-zA-Z0-9_-]{1,50}$", id)) {
    stop("Invalid sample ID format")
  }
  
  # Check for path traversal
  if (grepl("\\.\\.|/|\\\\", id)) {
    stop("Invalid characters in sample ID")
  }
  
  return(TRUE)
}

validate_file_upload <- function(file_path, allowed_extensions) {
  # Check file extension
  ext <- tools::file_ext(file_path)
  if (!ext %in% allowed_extensions) {
    stop("Invalid file type")
  }
  
  # Check file size
  size <- file.info(file_path)$size
  if (size > 500 * 1024^2) {
    stop("File too large")
  }
  
  # Check magic bytes (prevent extension spoofing)
  magic <- readBin(file_path, "raw", n = 4)
  # Implement magic byte validation
  
  # Virus scan (if ClamAV installed)
  if (system.file(package = "clamr") != "") {
    scan_result <- clamr::clamscan(file_path)
    if (scan_result$found > 0) {
      stop("File failed security scan")
    }
  }
  
  return(TRUE)
}
```

---

## Data Security

### 1. Encryption at Rest

#### Database Encryption
```sql
-- PostgreSQL with pgcrypto
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Encrypt sensitive columns
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email_encrypted BYTEA,  -- Encrypted email
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert with encryption
INSERT INTO users (username, email_encrypted)
VALUES ('jdoe', pgp_sym_encrypt('john@example.com', 'encryption_key'));

-- Query with decryption
SELECT username, pgp_sym_decrypt(email_encrypted, 'encryption_key') as email
FROM users;
```

#### File System Encryption
```bash
# LUKS encryption for data volume
sudo cryptsetup luksFormat /dev/sdb
sudo cryptsetup luksOpen /dev/sdb mdall_data
sudo mkfs.ext4 /dev/mapper/mdall_data
sudo mount /dev/mapper/mdall_data /data

# Add to /etc/crypttab for automatic mounting
mdall_data /dev/sdb none luks
```

#### Docker Volume Encryption
```yaml
# docker-compose.yml with encrypted volumes
volumes:
  mdall-data:
    driver: local
    driver_opts:
      type: none
      o: bind,encryption=aes-xts-plain64
      device: /encrypted/data
```

### 2. Encryption in Transit

#### TLS Configuration
```nginx
# nginx/nginx.conf - Strong SSL configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;

# HSTS
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
```

### 3. Data Retention & Disposal

```R
# modules/data_retention.R
library(logger)

# Automatic file cleanup
cleanup_old_files <- function(retention_days = 90) {
  
  # Find old temporary files
  temp_files <- list.files(
    "/data/temp",
    full.names = TRUE,
    recursive = TRUE
  )
  
  old_files <- temp_files[
    file.mtime(temp_files) < Sys.time() - retention_days * 86400
  ]
  
  # Secure deletion (overwrite + delete)
  for (file in old_files) {
    # Overwrite with random data 3 times (DoD 5220.22-M)
    for (i in 1:3) {
      size <- file.info(file)$size
      writeB(file, sample(0:255, size, replace = TRUE))
    }
    file.remove(file)
    log_audit("FILE_DELETED", file)
  }
  
  return(length(old_files))
}

# Schedule daily cleanup
cron_job <- list(
  frequency = "daily",
  time = "02:00",
  function = cleanup_old_files,
  args = list(retention_days = 90)
)
```

---

## Access Control

### 1. Role-Based Access Control (RBAC)

```R
# modules/rbac.R
roles <- list(
  admin = list(
    permissions = c("*"),  # All permissions
    description = "Full system access"
  ),
  researcher = list(
    permissions = c(
      "upload_data",
      "run_analysis",
      "view_results",
      "download_results"
    ),
    description = "Standard researcher access"
  ),
  viewer = list(
    permissions = c(
      "view_results"
    ),
    description = "Read-only access"
  )
)

check_permission <- function(user, permission) {
  user_role <- get_user_role(user)
  
  if ("*" %in% roles[[user_role]]$permissions) {
    return(TRUE)
  }
  
  return(permission %in% roles[[user_role]]$permissions)
}

# Usage in server
observe({
  if (!check_permission(current_user(), "run_analysis")) {
    showNotification("Access denied", type = "error")
    return()
  }
  # Proceed with analysis
})
```

### 2. IP Whitelisting

```nginx
# nginx/nginx.conf
geo $allowed_ip {
    default 0;
    10.0.0.0/8 1;           # Internal network
    192.168.1.0/24 1;       # Lab network
    172.16.50.100 1;        # VPN gateway
}

server {
    if ($allowed_ip = 0) {
        return 403;
    }
    # ... rest of configuration
}
```

---

## Audit & Monitoring

### 1. Comprehensive Audit Logging

```R
# modules/audit.R
library(logger)
library(jsonlite)

log_audit <- function(action, details = NULL) {
  # Get session info
  session_info <- list(
    user = get_current_user(),
    session_id = get_session_id(),
    ip_address = get_client_ip(),
    user_agent = get_user_agent(),
    timestamp = Sys.time(),
    action = action,
    details = details
  )
  
  # Log to file
  log_info(toJSON(session_info), namespace = "audit")
  
  # Log to database
  db_log_audit(session_info)
  
  # Alert on sensitive actions
  if (action %in% c("DATA_EXPORT", "USER_DELETED", "AUTH_FAILED")) {
    send_security_alert(session_info)
  }
}

# Actions to log
audit_actions <- c(
  "USER_LOGIN",
  "USER_LOGOUT",
  "AUTH_FAILED",
  "FILE_UPLOAD",
  "FILE_DOWNLOAD",
  "ANALYSIS_START",
  "ANALYSIS_COMPLETE",
  "DATA_VIEW",
  "DATA_EXPORT",
  "CONFIG_CHANGE",
  "USER_CREATED",
  "USER_DELETED",
  "PERMISSION_CHANGE"
)
```

### 2. Real-Time Monitoring

```bash
#!/bin/bash
# scripts/monitor-security.sh

# Monitor failed authentication attempts
tail -f /logs/mdall-app.log | grep "AUTH_FAILED" | while read line; do
    # Extract IP address
    IP=$(echo $line | grep -oP '(?<=ip":")[^"]+')
    
    # Count failures in last 5 minutes
    FAILURES=$(grep "AUTH_FAILED.*$IP" /logs/mdall-app.log | \
               grep -c "$(date -d '5 minutes ago' '+%Y-%m-%d %H:%M')")
    
    # Alert if > 5 failures
    if [ $FAILURES -gt 5 ]; then
        echo "ALERT: Multiple failed logins from $IP"
        # Send alert
        mail -s "Security Alert: Failed Logins" security@institution.edu <<< \
            "Multiple failed login attempts detected from IP: $IP"
        
        # Block IP
        ufw deny from $IP
    fi
done
```

### 3. Security Alerts

```R
# modules/alerts.R
send_security_alert <- function(event) {
  # Email alert
  email <- list(
    to = "security@institution.edu",
    from = "mdall-alerts@institution.edu",
    subject = paste("MD-ALL Security Alert:", event$action),
    body = paste(
      "Action:", event$action, "\n",
      "User:", event$user, "\n",
      "IP:", event$ip_address, "\n",
      "Time:", event$timestamp, "\n",
      "Details:", toJSON(event$details)
    )
  )
  
  send_email(email)
  
  # Log to SIEM
  send_to_siem(event)
}
```

---

## Incident Response

### 1. Incident Response Plan

#### Preparation
- [ ] Designate security officer
- [ ] Document contact information
- [ ] Establish escalation procedures
- [ ] Conduct annual training

#### Detection
- [ ] Monitor logs continuously
- [ ] Set up automated alerts
- [ ] Conduct weekly log reviews
- [ ] Perform quarterly security audits

#### Containment
```bash
# Emergency shutdown procedure
# /usr/local/bin/emergency-shutdown.sh

#!/bin/bash
echo "EMERGENCY SHUTDOWN INITIATED" | mail -s "CRITICAL" security@institution.edu

# Stop all services
docker-compose down

# Block all network traffic
ufw default deny incoming
ufw default deny outgoing
ufw allow from SECURITY_TEAM_IP to any port 22

# Backup current state
tar czf /backups/emergency-$(date +%Y%m%d-%H%M%S).tar.gz /data /logs

# Notify stakeholders
# ... notification script ...
```

#### Recovery
1. Identify root cause
2. Patch vulnerabilities
3. Restore from clean backup
4. Re-verify security controls
5. Document lessons learned

#### Post-Incident
- [ ] File breach notification (if PHI exposed)
- [ ] Update security procedures
- [ ] Conduct training
- [ ] Implement additional controls

### 2. Breach Notification Requirements

**Timeline:**
- **Discovery to HHS**: 60 days
- **Discovery to Individuals**: 60 days (if >500 affected)
- **Media Notification**: Without unreasonable delay (if >500 in jurisdiction)

**Documentation Required:**
- Date of breach discovery
- Date of breach occurrence (if different)
- Description of PHI involved
- Number of individuals affected
- Steps taken to mitigate harm
- Contact information

---

## Security Checklist

### Initial Deployment
- [ ] Server hardened (OS updates, firewall, SSH)
- [ ] Network segmentation configured
- [ ] VPN/secure access implemented
- [ ] SSL/TLS certificates installed
- [ ] Authentication enabled (LDAP/SSO)
- [ ] Multi-factor authentication configured
- [ ] Role-based access control implemented
- [ ] Audit logging enabled
- [ ] Data encryption at rest enabled
- [ ] Backup system configured
- [ ] Incident response plan documented
- [ ] Security contact information updated
- [ ] Users trained on security policies

### Daily Operations
- [ ] Review audit logs
- [ ] Check system alerts
- [ ] Monitor resource usage
- [ ] Verify backup completion
- [ ] Review failed login attempts

### Weekly Tasks
- [ ] Detailed log analysis
- [ ] Security patch review
- [ ] Access review (disable unused accounts)
- [ ] Certificate expiration check

### Monthly Tasks
- [ ] Full security audit
- [ ] Penetration testing (if required)
- [ ] Review and update access controls
- [ ] Test backup restoration
- [ ] Review incident response procedures

### Annual Tasks
- [ ] Security risk assessment
- [ ] HIPAA compliance audit
- [ ] Update Business Associate Agreements
- [ ] Security awareness training
- [ ] Disaster recovery drill
- [ ] Policy and procedure review

---

## Additional Resources

### Regulatory References
- **HIPAA Security Rule**: https://www.hhs.gov/hipaa/for-professionals/security/
- **NIST Cybersecurity Framework**: https://www.nist.gov/cyberframework
- **CIS Controls**: https://www.cisecurity.org/controls/

### Security Tools
- **Vulnerability Scanning**: OpenVAS, Nessus
- **Intrusion Detection**: Snort, Suricata, OSSEC
- **Log Management**: ELK Stack, Splunk
- **SIEM**: AlienVault, Wazuh

### Training Resources
- **HIPAA Training**: HHS Office for Civil Rights
- **Security Awareness**: SANS Security Awareness
- **Incident Response**: NIST SP 800-61

---

## Contact for Security Issues

**Security Team:**
- Email: security@your-institution.edu
- Phone: +1-XXX-XXX-XXXX
- On-call: [PagerDuty/On-call system]

**MD-ALL Development Team:**
- Email: zgu@coh.org
- For security vulnerabilities, use responsible disclosure

---

*This document should be reviewed and updated annually or whenever significant changes are made to the application or infrastructure.*

**Last Updated: 2024**
**Document Version: 1.0**
