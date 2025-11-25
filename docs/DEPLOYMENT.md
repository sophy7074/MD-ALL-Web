# MD-ALL Web Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation Methods](#installation-methods)
3. [Security Setup](#security-setup)
4. [Production Deployment](#production-deployment)
5. [Monitoring & Maintenance](#monitoring--maintenance)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Hardware Requirements
**Minimum (Testing/Development):**
- 4 CPU cores
- 16 GB RAM
- 50 GB SSD storage
- 1 Gbps network

**Recommended (Production):**
- 8+ CPU cores
- 32+ GB RAM
- 100+ GB SSD storage
- 10 Gbps network
- Redundant storage (RAID)

### Software Requirements
- **Operating System**: Ubuntu 22.04 LTS (recommended) or CentOS 8+
- **Docker**: Version 20.10 or later
- **Docker Compose**: Version 2.0 or later
- **SSL Certificate**: Valid certificate for your domain
- **Firewall**: Configured to allow ports 80, 443

### Network Requirements
- **For Clinical/PHI Data**: Deploy on secure institutional network
- **Access Control**: VPN or institutional network only
- **Firewall**: Whitelist specific IP ranges
- **SSL**: Required for all connections

---

## Installation Methods

### Method 1: Docker Deployment (Recommended)

#### Step 1: Clone Repository
```bash
git clone https://github.com/gu-lab20/MD-ALL-Web.git
cd MD-ALL-Web
```

#### Step 2: Configure Environment
```bash
# Copy example environment file
cp .env.example .env

# Edit configuration
nano .env
```

**Essential Environment Variables:**
```bash
# Authentication
ADMIN_PASSWORD=your_secure_password_here
AUTH_ENABLED=true

# Database
DB_PASSWORD=your_db_password_here

# Monitoring (optional)
GRAFANA_PASSWORD=your_grafana_password_here
```

#### Step 3: SSL Certificate Setup

**Option A: Self-Signed Certificate (Development Only)**
```bash
mkdir -p nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/key.pem \
  -out nginx/ssl/cert.pem
```

**Option B: Let's Encrypt (Production)**
```bash
# Install certbot
sudo apt-get update
sudo apt-get install certbot

# Obtain certificate
sudo certbot certonly --standalone \
  -d your-domain.com \
  -m your-email@example.com \
  --agree-tos

# Copy certificates
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem nginx/ssl/key.pem
sudo chmod 644 nginx/ssl/*.pem
```

**Option C: Institutional Certificate**
```bash
# Copy your institutional certificates
cp /path/to/your/cert.pem nginx/ssl/
cp /path/to/your/key.pem nginx/ssl/
```

#### Step 4: Build and Deploy
```bash
# Build the Docker image
docker-compose build

# Start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f mdall-app
```

#### Step 5: Verify Deployment
```bash
# Health check
curl -k https://localhost/health

# Access application
# Navigate to: https://your-server-ip
```

### Method 2: Shiny Server (Native R)

#### Step 1: Install R and Dependencies
```bash
# Install R (Ubuntu)
sudo apt-get update
sudo apt-get install -y r-base r-base-dev

# Install system dependencies
sudo apt-get install -y \
  libssl-dev libcurl4-openssl-dev libxml2-dev \
  libpng-dev libjpeg-dev libgit2-dev
```

#### Step 2: Install Shiny Server
```bash
# Download Shiny Server
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.20.1002-amd64.deb

# Install
sudo dpkg -i shiny-server-1.5.20.1002-amd64.deb

# Start service
sudo systemctl start shiny-server
sudo systemctl enable shiny-server
```

#### Step 3: Install R Packages
```bash
# Run R as root or use sudo
sudo R

# In R console:
install.packages(c("devtools", "BiocManager", "dplyr", "stringr", 
                   "Seurat", "ggplot2", "ggrepel", "cowplot", "umap",
                   "shiny", "shinyjs", "shinydashboard", "DT"))

BiocManager::install(c("DESeq2", "SingleR", "SummarizedExperiment"))

devtools::install_github("JinmiaoChenLab/Rphenograph")
devtools::install_github("gu-lab20/MD-ALL")
```

#### Step 4: Deploy Application
```bash
# Copy app to Shiny Server directory
sudo cp -r app/* /srv/shiny-server/mdall/

# Set permissions
sudo chown -R shiny:shiny /srv/shiny-server/mdall/

# Create data directories
sudo mkdir -p /data/{uploads,outputs,temp} /logs
sudo chown -R shiny:shiny /data /logs
```

#### Step 5: Configure Shiny Server
```bash
# Edit configuration
sudo nano /etc/shiny-server/shiny-server.conf

# Copy our production config
sudo cp shiny-server.conf /etc/shiny-server/

# Restart service
sudo systemctl restart shiny-server
```

---

## Security Setup

### 1. Firewall Configuration
```bash
# Ubuntu UFW
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# Or iptables
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -j DROP
```

### 2. Enable Authentication

Edit `.env` file:
```bash
AUTH_ENABLED=true
AUTH_TYPE=ldap  # or 'local' or 'sso'

# For LDAP
LDAP_HOST=ldap.your-institution.edu
LDAP_PORT=636
LDAP_BASE_DN=ou=users,dc=institution,dc=edu

# For local auth (development only)
ADMIN_USER=admin
ADMIN_PASSWORD=secure_password_here
```

### 3. HIPAA Compliance Checklist

For clinical/PHI data deployment:

- [ ] Deploy on institutional servers (NOT public cloud)
- [ ] Enable HTTPS/TLS encryption
- [ ] Implement user authentication (LDAP/SSO preferred)
- [ ] Enable audit logging
- [ ] Set up automatic log backups
- [ ] Configure data encryption at rest
- [ ] Implement network isolation (VPN/firewall)
- [ ] Set up regular security updates
- [ ] Configure session timeouts
- [ ] Implement access control lists
- [ ] Sign Business Associate Agreement (if applicable)
- [ ] Conduct security risk assessment
- [ ] Train users on data handling policies
- [ ] Set up incident response plan

### 4. Audit Logging

```bash
# Enable audit logging in .env
AUDIT_ENABLED=true

# View audit logs
docker-compose logs mdall-app | grep AUDIT

# Rotate logs daily
# Add to crontab:
0 0 * * * /usr/local/bin/rotate-logs.sh
```

---

## Production Deployment

### 1. High Availability Setup

#### Load Balancer Configuration (Nginx)
```nginx
upstream mdall_backend {
    least_conn;
    server mdall-app-1:3838;
    server mdall-app-2:3838;
    server mdall-app-3:3838;
}

server {
    listen 443 ssl http2;
    location / {
        proxy_pass http://mdall_backend;
    }
}
```

#### Docker Swarm (Alternative to Compose)
```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-stack.yml mdall

# Scale services
docker service scale mdall_mdall-app=3
```

### 2. Database Setup (PostgreSQL)

```sql
-- Initialize database schema
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255),
    role VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    action VARCHAR(255),
    details JSONB,
    ip_address INET,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE analysis_jobs (
    job_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id),
    sample_id VARCHAR(255),
    status VARCHAR(50),
    result_path TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);
```

### 3. Backup Strategy

```bash
#!/bin/bash
# backup-mdall.sh

# Backup directories
BACKUP_DIR="/backups/mdall/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Backup data
docker run --rm \
  -v mdall-data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/data.tar.gz /data

# Backup database
docker exec mdall-postgres \
  pg_dump -U mdall_user mdall > $BACKUP_DIR/database.sql

# Backup logs (last 7 days)
find /logs -mtime -7 -type f | tar czf $BACKUP_DIR/logs.tar.gz -T -

# Upload to secure storage (example with AWS S3)
aws s3 cp $BACKUP_DIR/ s3://your-backup-bucket/mdall/ --recursive

# Clean old backups (keep 30 days)
find /backups/mdall -mtime +30 -type d -exec rm -rf {} +
```

Add to crontab:
```bash
# Daily backup at 2 AM
0 2 * * * /usr/local/bin/backup-mdall.sh
```

---

## Monitoring & Maintenance

### 1. Health Monitoring

```bash
# Check application health
curl -f https://your-server/health || alert

# Monitor Docker containers
docker stats mdall-app

# Check logs for errors
docker-compose logs --tail=100 mdall-app | grep ERROR
```

### 2. Performance Monitoring (Prometheus + Grafana)

```bash
# Start monitoring stack
docker-compose --profile monitoring up -d

# Access Grafana
# Navigate to: http://your-server:3000
# Default login: admin / [GRAFANA_PASSWORD from .env]
```

### 3. Resource Usage

```bash
# Monitor CPU/Memory
htop

# Monitor disk space
df -h

# Monitor network
iftop

# Check R process memory
ps aux | grep shiny-server
```

### 4. Log Management

```bash
# View real-time logs
docker-compose logs -f

# Search logs
docker-compose logs | grep "ERROR\|WARN"

# Export logs
docker-compose logs > mdall-logs-$(date +%Y%m%d).txt

# Clean old logs
find /logs -name "*.log" -mtime +90 -delete
```

---

## Troubleshooting

### Common Issues

#### 1. Container Won't Start
```bash
# Check Docker logs
docker-compose logs mdall-app

# Common fixes:
# - Check port conflicts: lsof -i :3838
# - Check permissions: ls -la /data /logs
# - Check disk space: df -h
# - Rebuild image: docker-compose build --no-cache
```

#### 2. Out of Memory Errors
```bash
# Increase Docker memory limit
docker-compose down
# Edit docker-compose.yml:
#   memory: 32G

docker-compose up -d

# Or system-wide:
# Edit /etc/docker/daemon.json
{
  "default-shm-size": "2G",
  "memory": "32G"
}
sudo systemctl restart docker
```

#### 3. Authentication Issues
```bash
# Check authentication logs
docker-compose logs mdall-app | grep AUTH

# Test LDAP connection
ldapsearch -x -H ldap://your-ldap-server -b "ou=users,dc=example,dc=com"

# Reset admin password
docker-compose exec mdall-app \
  R -e "MDALL::reset_admin_password('newpassword')"
```

#### 4. Upload Failures
```bash
# Check upload directory permissions
docker-compose exec mdall-app ls -la /data/uploads

# Fix permissions
docker-compose exec mdall-app chown -R shiny:shiny /data/uploads

# Check max upload size
docker-compose exec mdall-app grep client_max_body_size /etc/nginx/nginx.conf

# Increase limit in docker-compose.yml:
# UPLOAD_MAX_SIZE_MB=1000
```

#### 5. SSL Certificate Errors
```bash
# Check certificate validity
openssl x509 -in nginx/ssl/cert.pem -text -noout

# Verify certificate chain
openssl verify -CAfile nginx/ssl/chain.pem nginx/ssl/cert.pem

# Renew Let's Encrypt certificate
sudo certbot renew
sudo cp /etc/letsencrypt/live/your-domain.com/*.pem nginx/ssl/
docker-compose restart nginx
```

#### 6. Analysis Fails
```bash
# Check R package versions
docker-compose exec mdall-app R -e "packageVersion('MDALL')"

# Update packages
docker-compose exec mdall-app R -e "
devtools::install_github('gu-lab20/MD-ALL', force=TRUE)
"

# Check input file format
docker-compose exec mdall-app head /data/uploads/your-file.txt

# Check temp directory space
docker-compose exec mdall-app df -h /data/temp
```

### Getting Help

1. **Check Logs**: Always start with logs
   ```bash
   docker-compose logs --tail=100 mdall-app
   ```

2. **GitHub Issues**: Report bugs or ask questions
   - https://github.com/gu-lab20/MD-ALL/issues

3. **Email Support**:
   - Technical: zuhu@coh.org
   - Scientific: zgu@coh.org

4. **Documentation**: Review package documentation
   ```R
   library(MDALL)
   ?MDALL
   ```

---

## Updates & Upgrades

### Updating MD-ALL Package
```bash
# Stop services
docker-compose down

# Rebuild with latest version
docker-compose build --no-cache

# Start services
docker-compose up -d

# Verify version
docker-compose exec mdall-app R -e "packageVersion('MDALL')"
```

### System Updates
```bash
# Update OS packages
sudo apt-get update && sudo apt-get upgrade -y

# Update Docker
sudo apt-get install docker-ce docker-ce-cli containerd.io

# Update Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

---

## Appendix: Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `AUTH_ENABLED` | `false` | Enable user authentication |
| `AUTH_TYPE` | `local` | Authentication type: local, ldap, sso |
| `ADMIN_USER` | `admin` | Admin username |
| `ADMIN_PASSWORD` | `changeme` | Admin password (CHANGE THIS!) |
| `LOG_LEVEL` | `INFO` | Logging level: DEBUG, INFO, WARN, ERROR |
| `AUDIT_ENABLED` | `false` | Enable audit logging |
| `MAX_WORKERS` | `4` | Maximum concurrent analyses |
| `MAX_MEMORY_GB` | `16` | Maximum memory per worker |
| `UPLOAD_MAX_SIZE_MB` | `500` | Maximum upload file size |
| `SESSION_TIMEOUT` | `3600` | Session timeout in seconds |
| `TEMP_DIR` | `/data/temp` | Temporary file directory |
| `OUTPUT_DIR` | `/data/outputs` | Output file directory |

---

*Last updated: 2024*
*For the latest version, visit: https://github.com/gu-lab20/MD-ALL*
