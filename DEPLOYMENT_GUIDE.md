# PHP Application Deployment Guide for Ubuntu Server

This guide will help you deploy the PHP application on an Ubuntu server using either Nginx or Apache.

## Prerequisites

- Ubuntu 20.04+ server
- Root or sudo access
- Domain name (optional but recommended)

## Option 1: Deploy with Nginx + PHP-FPM

### Step 1: Update System and Install Dependencies

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Nginx, PHP-FPM, and required PHP extensions
sudo apt install nginx php8.1-fpm php8.1-cli php8.1-common php8.1-mysql php8.1-zip php8.1-gd php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath php8.1-json php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip -y

# Install Git for cloning repository
sudo apt install git -y
```

### Step 2: Configure PHP-FPM

```bash
# Edit PHP-FPM configuration
sudo nano /etc/php/8.1/fpm/php.ini

# Make these changes:
# upload_max_filesize = 100M
# post_max_size = 100M
# max_execution_time = 300
# memory_limit = 256M

# Restart PHP-FPM
sudo systemctl restart php8.1-fpm
sudo systemctl enable php8.1-fpm
```

### Step 3: Clone and Setup Application

```bash
# Create web directory
sudo mkdir -p /var/www/html/comm

# Clone repository
sudo git clone https://github.com/kamrankamrankhan/comm.git /var/www/html/comm

# Set proper permissions
sudo chown -R www-data:www-data /var/www/html/comm
sudo chmod -R 755 /var/www/html/comm

# Set write permissions for uploads directory
sudo chmod -R 777 /var/www/html/comm/views/xentryxupload/
```

### Step 4: Configure Nginx

```bash
# Create Nginx configuration
sudo nano /etc/nginx/sites-available/comm
```

### Step 5: Start Services

```bash
# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Check status
sudo systemctl status nginx
sudo systemctl status php8.1-fpm
```

## Option 2: Deploy with Apache

### Step 1: Update System and Install Dependencies

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Apache and PHP
sudo apt install apache2 php8.1 libapache2-mod-php8.1 php8.1-cli php8.1-common php8.1-mysql php8.1-zip php8.1-gd php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath php8.1-json -y

# Install Git
sudo apt install git -y
```

### Step 2: Configure Apache

```bash
# Enable required Apache modules
sudo a2enmod rewrite
sudo a2enmod ssl
sudo a2enmod headers

# Create Apache virtual host
sudo nano /etc/apache2/sites-available/comm.conf
```

### Step 3: Clone and Setup Application

```bash
# Create web directory
sudo mkdir -p /var/www/html/comm

# Clone repository
sudo git clone https://github.com/kamrankamrankhan/comm.git /var/www/html/comm

# Set proper permissions
sudo chown -R www-data:www-data /var/www/html/comm
sudo chmod -R 755 /var/www/html/comm

# Set write permissions for uploads
sudo chmod -R 777 /var/www/html/comm/views/xentryxupload/
```

### Step 4: Start Services

```bash
# Enable site and restart Apache
sudo a2ensite comm.conf
sudo systemctl restart apache2
sudo systemctl enable apache2

# Check status
sudo systemctl status apache2
```

## Security Considerations

### 1. Firewall Configuration

```bash
# Configure UFW firewall
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

### 2. SSL Certificate (Let's Encrypt)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y  # For Nginx
# OR
sudo apt install certbot python3-certbot-apache -y  # For Apache

# Get SSL certificate
sudo certbot --nginx -d yourdomain.com  # For Nginx
# OR
sudo certbot --apache -d yourdomain.com  # For Apache
```

### 3. Application Security

- Re-enable geographic restrictions in production
- Configure proper file permissions
- Set up regular backups
- Monitor logs for suspicious activity

## Monitoring and Maintenance

### Log Files

```bash
# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Apache logs
sudo tail -f /var/log/apache2/access.log
sudo tail -f /var/log/apache2/error.log

# PHP logs
sudo tail -f /var/log/php8.1-fpm.log
```

### Backup Script

```bash
# Create backup script
sudo nano /usr/local/bin/backup-comm.sh
```

## Troubleshooting

### Common Issues

1. **Permission denied errors**: Check file ownership and permissions
2. **PHP not working**: Ensure PHP-FPM is running (Nginx) or mod_php is enabled (Apache)
3. **404 errors**: Check virtual host configuration and document root
4. **Upload issues**: Verify upload directory permissions

### Useful Commands

```bash
# Check PHP version
php -v

# Test PHP configuration
php -m

# Check service status
sudo systemctl status nginx
sudo systemctl status apache2
sudo systemctl status php8.1-fpm

# Restart services
sudo systemctl restart nginx
sudo systemctl restart apache2
sudo systemctl restart php8.1-fpm
```

## Next Steps

1. Configure your domain name DNS to point to your server
2. Set up SSL certificate
3. Configure monitoring and logging
4. Set up automated backups
5. Test all application functionality
6. Re-enable security restrictions for production use
