#!/bin/bash

# Complete Server Cleanup and Fresh Deployment Script
# Run this script on your server as root

set -e  # Exit on any error

echo "🧹 Starting complete server cleanup and fresh deployment..."

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

# Step 1: Stop all services
print_status "Stopping all services..."
systemctl stop nginx 2>/dev/null || true
systemctl stop php7.2-fpm 2>/dev/null || true
systemctl stop php8.1-fpm 2>/dev/null || true
print_success "Services stopped"

# Step 2: Remove existing application files
print_status "Removing existing application files..."
rm -rf /var/www/html/comm
rm -rf /var/www/html/*
print_success "Application files removed"

# Step 3: Remove all Nginx configurations
print_status "Removing Nginx configurations..."
rm -f /etc/nginx/sites-available/comm
rm -f /etc/nginx/sites-enabled/comm
rm -f /etc/nginx/sites-available/commerzbank-update.info
rm -f /etc/nginx/sites-enabled/commerzbank-update.info
rm -f /etc/nginx/sites-enabled/default
print_success "Nginx configurations removed"

# Step 4: Clean up any existing git repositories
print_status "Cleaning up git repositories..."
rm -rf /var/www/html/comm.git
rm -rf /tmp/comm-deploy
print_success "Git repositories cleaned"

# Step 5: Update system packages
print_status "Updating system packages..."
apt update -y
print_success "System packages updated"

# Step 6: Install required packages
print_status "Installing required packages..."
apt install -y nginx git curl wget unzip
print_success "Required packages installed"

# Step 7: Install PHP 7.2 (matching your server)
print_status "Installing PHP 7.2..."
apt install -y php7.2 php7.2-fpm php7.2-mysql php7.2-curl php7.2-gd php7.2-mbstring php7.2-xml php7.2-zip
print_success "PHP 7.2 installed"

# Step 8: Start PHP-FPM
print_status "Starting PHP-FPM..."
systemctl start php7.2-fpm
systemctl enable php7.2-fpm
print_success "PHP-FPM started and enabled"

# Step 9: Clone the repository
print_status "Cloning application repository..."
cd /var/www/html
git clone https://github.com/kamrankamrankhan/comm.git comm
print_success "Repository cloned"

# Step 10: Set proper permissions
print_status "Setting proper permissions..."
chown -R www-data:www-data /var/www/html/comm
chmod -R 755 /var/www/html/comm
find /var/www/html/comm -type f -name "*.php" -exec chmod 644 {} \;
print_success "Permissions set"

# Step 11: Create Nginx configuration
print_status "Creating Nginx configuration..."
cat > /etc/nginx/sites-available/commerzbank-update.info << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name 193.124.205.44 localhost;
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

# Step 12: Enable the site
print_status "Enabling Nginx site..."
ln -sf /etc/nginx/sites-available/commerzbank-update.info /etc/nginx/sites-enabled/
print_success "Nginx site enabled"

# Step 13: Test Nginx configuration
print_status "Testing Nginx configuration..."
nginx -t
print_success "Nginx configuration test passed"

# Step 14: Start and enable Nginx
print_status "Starting Nginx..."
systemctl start nginx
systemctl enable nginx
print_success "Nginx started and enabled"

# Step 15: Configure firewall (if ufw is available)
if command -v ufw &> /dev/null; then
    print_status "Configuring firewall..."
    ufw allow 'Nginx Full'
    ufw allow ssh
    print_success "Firewall configured"
fi

# Step 16: Get server IP
SERVER_IP=$(curl -s ifconfig.me)
print_success "Server IP: $SERVER_IP"

# Step 17: Test the deployment
print_status "Testing deployment..."
sleep 2
if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|302"; then
    print_success "Deployment test successful!"
else
    print_warning "Deployment test returned non-200 status"
fi

# Final status
echo ""
echo "🎉 DEPLOYMENT COMPLETE!"
echo "=========================="
echo "Server IP: $SERVER_IP"
echo "Access URL: http://$SERVER_IP"
echo "Local URL: http://localhost"
echo ""
echo "📋 Next Steps:"
echo "1. Test the application: http://$SERVER_IP"
echo "2. Check logs if needed: tail -f /var/log/nginx/commerzbank_error.log"
echo "3. Monitor services: systemctl status nginx php7.2-fpm"
echo ""
print_success "Fresh deployment completed successfully!"
