# MD-ALL Web Server Deployment

## Overview
MD-ALL (Molecular Diagnosis of Acute Lymphoblastic Leukemia) - Web Server Edition

This is a web-deployable version of the MD-ALL R package for B-ALL subtype classification using RNA-seq data. The application can be hosted on institutional servers with proper security controls for clinical genomics data.

## Features
- 🔬 Classify B-ALL into 26 subtypes using bulk RNA-seq
- 🧬 Single-cell RNA-seq analysis support
- 🔐 Enterprise-grade security with authentication
- 📊 Interactive visualizations and reports
- 🚀 Docker containerization for easy deployment
- 📝 Comprehensive audit logging for clinical compliance

## Citation
Zunsong Hu, Zhilian Jia, Jiangyue Liu, Allen Mao, Helen Han, Zhaohui Gu. **MD-ALL: an integrative platform for molecular diagnosis of B-acute lymphoblastic leukemia.** *Haematologica.* 2024 Jun 1;109(6):1741-1754. doi: 10.3324/haematol.2023.283706

## System Requirements

### Minimum Hardware
- **CPU**: 4 cores
- **RAM**: 16 GB (32 GB recommended for production)
- **Storage**: 50 GB SSD
- **Network**: Secure intranet connection

### Software Requirements
- Docker 20.10+ OR
- R 4.2+ with Shiny Server
- Linux/Unix server (Ubuntu 22.04 LTS recommended)
- SSL certificate for HTTPS

## Quick Start with Docker (Recommended)

### 1. Clone Repository
```bash
git clone https://github.com/gu-lab20/MD-ALL-Web.git
cd MD-ALL-Web
```

### 2. Build Docker Image
```bash
docker build -t mdall-web:latest .
```

### 3. Run Container
```bash
docker run -d \
  --name mdall-app \
  -p 3838:3838 \
  -v /path/to/data:/data \
  -v /path/to/logs:/logs \
  -e AUTH_ENABLED=true \
  -e ADMIN_PASSWORD=changeme \
  mdall-web:latest
```

### 4. Access Application
Navigate to: `https://your-server:3838`

## Deployment Options

### Option 1: Docker Deployment (Recommended)
Best for: Production environments, institutional deployment
- See `docker/README.md` for detailed instructions
- Includes security hardening and monitoring

### Option 2: Shiny Server
Best for: R-native environments, on-premise servers
- See `shiny-server/README.md` for setup
- Requires manual R package installation

### Option 3: ShinyApps.io
Best for: Pilot studies, non-PHI data only
- See `shinyapps/README.md` for deployment
- ⚠️ NOT recommended for clinical/HIPAA data

### Option 4: Posit Connect (RStudio Connect)
Best for: Enterprise R deployments
- Commercial solution with enterprise features
- Built-in authentication and scaling

## Security Considerations

### For Clinical Data (HIPAA/PHI)
⚠️ **IMPORTANT**: This application handles potentially sensitive genomic data

**Required Security Measures:**
1. ✅ Deploy on secure institutional servers (NOT public cloud)
2. ✅ Enable HTTPS/TLS encryption
3. ✅ Implement user authentication
4. ✅ Enable audit logging
5. ✅ Regular security updates
6. ✅ Data encryption at rest
7. ✅ Network isolation/VPN access
8. ✅ Regular backups
9. ✅ Access control lists (ACLs)
10. ✅ HIPAA Business Associate Agreement (if applicable)

**See `docs/SECURITY.md` for complete guidelines**

## Configuration

### Environment Variables
```bash
# Authentication
AUTH_ENABLED=true
AUTH_TYPE=ldap|local|sso
ADMIN_USER=admin
ADMIN_PASSWORD=changeme

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=mdall
DB_USER=mdall_user

# Logging
LOG_LEVEL=INFO
LOG_PATH=/logs
AUDIT_ENABLED=true

# Compute Resources
MAX_WORKERS=4
MAX_MEMORY_GB=16
UPLOAD_MAX_SIZE_MB=500
```

### File Uploads
- Maximum file size: 500 MB (configurable)
- Supported formats: .txt, .tsv, .csv, .vcf, .gz
- Files are automatically deleted after analysis (configurable retention)

## User Guide

### Input Files

#### Bulk RNA-seq (Minimum Required)
- **Gene counts**: HTSeq or FeatureCounts output
- Format: Gene ID (ENSG) + raw counts

#### Optional Files (Improve Accuracy)
- **VCF file**: GATK HaplotypeCaller output
- **FusionCatcher**: `final-list_candidate-fusion-genes.txt`
- **Cicero**: Fusion calls output

#### Single-cell RNA-seq
- Gene (rows) × Cell (columns) expression matrix
- Format: TSV with ENSG gene IDs

### Analysis Modes

1. **Single Sample**: Analyze one sample at a time
2. **Multiple Samples**: Batch analysis with metadata table
3. **Count Matrix Only**: GEP-based prediction without additional files
4. **Single-cell**: scRNA-seq subtyping

### Output

**For each sample:**
- 📊 GEP-based subtype predictions (SVM + PhenoGraph)
- 🧬 Copy number variation analysis (if VCF provided)
- 🔀 B-ALL mutation calls
- 🔗 Fusion detection results
- 📋 Comprehensive PDF report
- 💾 Downloadable results (CSV/TSV)

## Performance

**Typical Analysis Time** (per sample):
- GEP only: 1-2 minutes
- With VCF: 3-5 minutes
- With fusion calling: 5-10 minutes
- scRNA-seq (10K cells): 10-15 minutes

**Concurrent Users**: Supports 10+ simultaneous users (with 32 GB RAM)

## Monitoring & Maintenance

### Health Checks
```bash
# Check application status
curl https://your-server:3838/health

# View logs
docker logs mdall-app --tail 100

# Monitor resources
docker stats mdall-app
```

### Backup Strategy
```bash
# Backup logs
tar -czf logs-backup-$(date +%Y%m%d).tar.gz /path/to/logs

# Backup database (if using)
pg_dump mdall > mdall-backup-$(date +%Y%m%d).sql
```

## Troubleshooting

### Common Issues

**1. Out of Memory Errors**
- Increase Docker memory limit: `--memory="32g"`
- Reduce `MAX_WORKERS` in config

**2. Authentication Failed**
- Check LDAP configuration
- Verify user credentials
- Review auth logs: `docker logs mdall-app | grep AUTH`

**3. Analysis Fails**
- Check input file formats
- Verify file permissions
- Review error logs in UI

**4. Slow Performance**
- Check CPU/memory usage
- Reduce concurrent analyses
- Consider upgrading hardware

See `docs/TROUBLESHOOTING.md` for detailed solutions

## Support & Contributing

### Getting Help
- 📧 Email: zuhu@coh.org, zgu@coh.org
- 🐛 Issues: GitHub Issues page
- 📚 Documentation: `docs/` directory

### Contributing
We welcome contributions! Please see `CONTRIBUTING.md` for guidelines.

## License
This project maintains the same license as the original MD-ALL package.

## Acknowledgments
- Original MD-ALL development team at City of Hope
- Beckman Research Institute
- NIH/NCI Pathway to Independence Award R00 CA241297
- Leukemia and Lymphoma Society

## Version History
- v1.0.0 (2024): Initial web server deployment
- Based on MD-ALL package published in Haematologica 2024

---

**⚠️ Disclaimer**: This software is for research use only. Not for diagnostic purposes without proper clinical validation.
