# MD-ALL Web Server - Quick Start Guide

## 🚀 5-Minute Setup (Development/Testing)

For a quick test deployment **without clinical data**:

```bash
# 1. Clone repository
git clone https://github.com/gu-lab20/MD-ALL-Web.git
cd MD-ALL-Web

# 2. Create self-signed SSL certificate
mkdir -p nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/key.pem \
  -out nginx/ssl/cert.pem \
  -subj "/C=US/ST=CA/L=LA/O=YourOrg/CN=localhost"

# 3. Configure environment
cp .env.example .env
# Edit .env and change ADMIN_PASSWORD

# 4. Build and run
docker-compose build
docker-compose up -d

# 5. Access application
echo "Application ready at: https://localhost"
```

**⚠️ WARNING**: This setup is for testing only. See full deployment guide for production.

---

## 📋 Production Deployment Checklist

### Pre-Deployment
- [ ] Review security requirements (see `docs/SECURITY.md`)
- [ ] Obtain institutional SSL certificate
- [ ] Configure institutional authentication (LDAP/SSO)
- [ ] Set up secure server environment
- [ ] Configure firewall and network security
- [ ] Plan backup strategy

### Deployment Steps
1. **Server Preparation**
   ```bash
   # Update system
   sudo apt-get update && sudo apt-get upgrade -y
   
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   
   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

2. **Application Setup**
   ```bash
   # Clone repository
   cd /opt
   sudo git clone https://github.com/gu-lab20/MD-ALL-Web.git
   cd MD-ALL-Web
   
   # Configure environment
   sudo cp .env.example .env
   sudo nano .env  # Edit configuration
   ```

3. **SSL Certificate**
   ```bash
   # Copy institutional certificates
   sudo mkdir -p nginx/ssl
   sudo cp /path/to/cert.pem nginx/ssl/
   sudo cp /path/to/key.pem nginx/ssl/
   sudo chmod 644 nginx/ssl/*.pem
   ```

4. **Build and Deploy**
   ```bash
   # Build Docker image
   sudo docker-compose build
   
   # Start services
   sudo docker-compose up -d
   
   # Check status
   sudo docker-compose ps
   sudo docker-compose logs -f
   ```

5. **Verify Deployment**
   ```bash
   # Health check
   curl -k https://localhost/health
   
   # Check logs
   sudo docker-compose logs mdall-app | tail -50
   ```

### Post-Deployment
- [ ] Test authentication
- [ ] Verify file uploads work
- [ ] Run test analysis
- [ ] Configure monitoring
- [ ] Set up automated backups
- [ ] Document administrator contacts
- [ ] Train users

---

## 🔧 Common Configurations

### Configuration 1: Internal Server with LDAP
**Use Case**: Hospital/university with existing LDAP
```bash
# .env settings
AUTH_ENABLED=true
AUTH_TYPE=ldap
LDAP_HOST=ldap.institution.edu
LDAP_PORT=636
LDAP_BASE_DN=ou=users,dc=institution,dc=edu
ALLOWED_IPS=10.0.0.0/8  # Internal network only
```

### Configuration 2: Cloud VM with SSO
**Use Case**: Research group using institutional SSO
```bash
# .env settings
AUTH_ENABLED=true
AUTH_TYPE=sso
SSO_IDP_URL=https://idp.institution.edu/sso
FORCE_HTTPS=true
RATE_LIMIT=50  # Limit requests
```

### Configuration 3: High-Performance Setup
**Use Case**: Large-scale analysis, multiple concurrent users
```bash
# docker-compose.yml
services:
  mdall-app:
    deploy:
      resources:
        limits:
          cpus: '16'
          memory: 64G
      replicas: 3  # Multiple instances

# .env settings
MAX_WORKERS=16
MAX_MEMORY_GB=32
SHINY_WORKERS=8
```

---

## 📊 Usage Examples

### Example 1: Single Sample Analysis
1. Navigate to `https://your-server/`
2. Click "Bulk RNA-seq" → "Single Sample"
3. Upload gene count file (required)
4. Optionally upload VCF, FusionCatcher files
5. Click "Run Analysis"
6. View results in tabs: Summary, GEP, CNV, Mutations, Fusions
7. Download PDF report

### Example 2: Batch Analysis
1. Prepare metadata CSV:
   ```csv
   sample_id,count_file,vcf_file,fusioncatcher_file
   Sample1,/path/to/sample1_counts.txt,/path/to/sample1.vcf,/path/to/sample1_fusions.txt
   Sample2,/path/to/sample2_counts.txt,/path/to/sample2.vcf,
   ```
2. Select "Bulk RNA-seq" → "Multiple Samples"
3. Upload metadata file
4. Upload all data files
5. Click "Run Analysis"
6. View/download results for each sample

### Example 3: Single-Cell Analysis
1. Prepare count matrix (genes × cells)
2. Select "Single-cell RNA-seq"
3. Upload matrix file
4. Click "Run Analysis"
5. View UMAP plots and cell-type annotations

---

## 🔍 Monitoring & Maintenance

### Daily Checks
```bash
# Check service status
docker-compose ps

# Check disk space
df -h

# View recent logs
docker-compose logs --tail=100 mdall-app
```

### Weekly Tasks
```bash
# Review full logs
docker-compose logs mdall-app > logs-$(date +%Y%m%d).txt

# Check for updates
cd /opt/MD-ALL-Web
git fetch origin
git log HEAD..origin/main --oneline

# Backup data
tar czf /backups/mdall-data-$(date +%Y%m%d).tar.gz /data
```

### Monthly Tasks
```bash
# Update application
cd /opt/MD-ALL-Web
git pull origin main
docker-compose build --no-cache
docker-compose up -d

# Clean old files
find /data/temp -mtime +90 -delete
find /logs -name "*.log" -mtime +90 -delete
```

---

## 🆘 Quick Troubleshooting

### Problem: Can't access application
```bash
# Check if container is running
docker-compose ps

# Check logs for errors
docker-compose logs mdall-app | grep ERROR

# Restart services
docker-compose restart
```

### Problem: Authentication fails
```bash
# Check auth logs
docker-compose logs mdall-app | grep AUTH

# Test LDAP connection (if using LDAP)
ldapsearch -x -H ldap://your-ldap-server -b "ou=users,dc=example,dc=com"

# Reset admin password
docker-compose exec mdall-app R -e "MDALL::reset_password('admin', 'newpass')"
```

### Problem: Analysis fails
```bash
# Check R process
docker-compose exec mdall-app ps aux | grep shiny

# Check memory
docker stats mdall-app

# Check temp directory
docker-compose exec mdall-app df -h /data/temp

# View detailed error
docker-compose logs mdall-app --tail=200
```

### Problem: Out of memory
```bash
# Increase Docker memory
# Edit docker-compose.yml, set memory: 32G
docker-compose down
docker-compose up -d

# Or increase system swap
sudo fallocate -l 16G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

---

## 📚 Additional Resources

- **Full Deployment Guide**: `docs/DEPLOYMENT.md`
- **Security & HIPAA Compliance**: `docs/SECURITY.md`
- **API Documentation**: `docs/API.md`
- **Troubleshooting Guide**: `docs/TROUBLESHOOTING.md`

---

## 📞 Support

**For Technical Issues:**
- GitHub Issues: https://github.com/gu-lab20/MD-ALL/issues
- Email: zuhu@coh.org

**For Scientific Questions:**
- Email: zgu@coh.org

**For Security Concerns:**
- Email: security@your-institution.edu

---

## 📝 Notes

1. **ALWAYS change default passwords** before deployment
2. **Use institutional certificates** for production
3. **Enable authentication** for any non-public deployment
4. **Review security documentation** before handling PHI
5. **Test backup restoration** regularly
6. **Document your deployment** for future reference

---

**Last Updated**: 2024  
**Version**: 1.0.0  
**Based on**: MD-ALL package (Haematologica 2024)
