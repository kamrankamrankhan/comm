#!/bin/bash

# PHP Application Deployment Script for Nginx + PHP-FPM
# Run this script as root or with sudo

set -e

echo "🚀 Starting PHP Application Deployment with Nginx..."

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
print_status "Installing Nginx, PHP-FPM, and dependencies..."
apt install -y nginx php8.1-fpm php8.1-cli php8.1-common php8.1-mysql php8.1-zip php8.1-gd php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath php8.1-json git

# Step 3: Configure PHP-FPM
print_status "Configuring PHP-FPM..."
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/' /etc/php/8.1/fpm/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 100M/' /etc/php/8.1/fpm/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/8.1/fpm/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 256M/' /etc/php/8.1/fpm/php.ini

# Step 4: Create web directory and clone repository
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

# Step 5: Configure Nginx
print_status "Configuring Nginx..."
cat > /etc/nginx/sites-available/comm << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    root /var/www/html/comm;
    index index.php index.html index.htm;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Hide Nginx version
    server_tokens off;

    # Main location block
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        
        # Security settings
        fastcgi_hide_header X-Powered-By;
        fastcgi_read_timeout 300;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
    }

    # Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~ /(config|antibot|prevents)/ {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Deny access to backup and temporary files
    location ~* \.(bak|backup|old|tmp|temp|log)$ {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Handle uploads directory
    location /views/xentryxupload/ {
        try_files \$uri \$uri/ =404;
        
        # Allow uploads
        client_max_body_size 100M;
        client_body_timeout 300;
        client_header_timeout 300;
    }

    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Robots.txt
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # Error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    
    location = /50x.html {
        root /usr/share/nginx/html;
    }

    # Logging
    access_log /var/log/nginx/comm_access.log;
    error_log /var/log/nginx/comm_error.log;
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/comm /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
print_status "Testing Nginx configuration..."
nginx -t

# Step 6: Configure firewall
print_status "Configuring firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Step 7: Start and enable services
print_status "Starting services..."
systemctl restart php8.1-fpm
systemctl enable php8.1-fpm
systemctl restart nginx
systemctl enable nginx

# Step 8: Create backup script
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
print_warning "2. Install SSL certificate: certbot --nginx -d $DOMAIN_NAME"
print_warning "3. Re-enable security restrictions in /var/www/html/comm/prevents/genius.php"
print_warning "4. Test all application functionality"

# Show service status
print_status "Service status:"
systemctl status nginx --no-pager -l
systemctl status php8.1-fpm --no-pager -l

echo ""
print_status "🎉 Deployment script completed!"
