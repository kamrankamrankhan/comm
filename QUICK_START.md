# 🚀 Quick Start Deployment Guide

## Choose Your Web Server

### Option 1: Nginx + PHP-FPM (Recommended)
```bash
# Download and run the Nginx deployment script
wget https://raw.githubusercontent.com/kamrankamrankhan/comm/main/deploy-nginx.sh
chmod +x deploy-nginx.sh
sudo ./deploy-nginx.sh
```

### Option 2: Apache
```bash
# Download and run the Apache deployment script
wget https://raw.githubusercontent.com/kamrankamrankhan/comm/main/deploy-apache.sh
chmod +x deploy-apache.sh
sudo ./deploy-apache.sh
```

## Post-Deployment Security

After deployment, run the security hardening script:

```bash
# Download and run security hardening
wget https://raw.githubusercontent.com/kamrankamrankhan/comm/main/security-hardening.sh
chmod +x security-hardening.sh
sudo ./security-hardening.sh
```

## SSL Certificate Setup

### For Nginx:
```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d yourdomain.com
```

### For Apache:
```bash
sudo apt install certbot python3-certbot-apache -y
sudo certbot --apache -d yourdomain.com
```

## Manual Deployment Steps

If you prefer manual deployment, follow the detailed guide in `DEPLOYMENT_GUIDE.md`.

## Files Included

- `DEPLOYMENT_GUIDE.md` - Complete deployment instructions
- `deploy-nginx.sh` - Automated Nginx deployment script
- `deploy-apache.sh` - Automated Apache deployment script
- `security-hardening.sh` - Security hardening script
- `nginx-config.conf` - Nginx configuration template
- `apache-config.conf` - Apache configuration template

## Support

For issues or questions, please check the logs:
- Nginx: `/var/log/nginx/comm_error.log`
- Apache: `/var/log/apache2/comm_error.log`
- Application: `/var/log/comm-monitor.log`

## Security Notes

⚠️ **Important**: The deployment scripts temporarily disable geographic restrictions for testing. Make sure to run the security hardening script after deployment to re-enable all security features.

🔒 **Production**: Always use HTTPS in production and regularly update your system.
