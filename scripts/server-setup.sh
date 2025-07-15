#!/bin/bash

# Bitcoin Efectivo Server Setup Script
# This script sets up a Ubuntu/Debian server for hosting the Bitcoin Efectivo website and API

set -e

# Configuration
DOMAIN="bitcoinefectivo.com"
WEBROOT="/var/www/${DOMAIN}"
USER="bitcoinefectivo"
NODE_VERSION="18"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

log_info "Starting Bitcoin Efectivo server setup..."

# Update system
log_info "Updating system packages..."
apt update && apt upgrade -y

# Install basic dependencies
log_info "Installing basic dependencies..."
apt install -y curl wget git ufw fail2ban htop tree vim nano

# Remove existing Node.js installations
log_info "Removing existing Node.js installations..."
apt remove -y nodejs npm libnode-dev node-gyp || true
apt autoremove -y

# Clean up any remaining Node.js files
rm -rf /usr/lib/node_modules
rm -rf /usr/include/node
rm -f /usr/bin/node
rm -f /usr/bin/npm

# Install Node.js
log_info "Installing Node.js ${NODE_VERSION}..."
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
apt install -y nodejs

# Verify Node.js installation
node_version=$(node --version)
npm_version=$(npm --version)
log_success "Node.js ${node_version} and npm ${npm_version} installed"

# Install nginx
log_info "Installing nginx..."
apt install -y nginx

# Install certbot for SSL certificates
log_info "Installing certbot..."
apt install -y certbot python3-certbot-nginx

# Create application user
log_info "Creating application user..."
if ! id "$USER" &>/dev/null; then
    useradd -m -s /bin/bash -G sudo "$USER"
    log_success "User $USER created"
else
    log_warn "User $USER already exists"
fi

# Create web directory
log_info "Creating web directory..."
mkdir -p "$WEBROOT"
chown -R "$USER:$USER" "$WEBROOT"

# Create application directory
log_info "Creating application directory..."
mkdir -p "/home/$USER/be-backend"
chown -R "$USER:$USER" "/home/$USER/be-backend"

# Configure UFW firewall
log_info "Configuring firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable

# Configure fail2ban
log_info "Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
EOF

systemctl enable fail2ban
systemctl start fail2ban

# Create systemd service for the API
log_info "Creating systemd service..."
cat > /etc/systemd/system/be-api.service << EOF
[Unit]
Description=Bitcoin Efectivo API Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/home/$USER/be-backend
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=3000

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/home/$USER/be-backend
ProtectHome=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable be-api

# Create log rotation
log_info "Setting up log rotation..."
cat > /etc/logrotate.d/be-api << EOF
/var/log/be-api.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0644 $USER $USER
}
EOF

# Create deployment script
log_info "Creating deployment script..."
cat > /home/$USER/deploy.sh << 'EOF'
#!/bin/bash

# Bitcoin Efectivo Deployment Script

set -e

REPO_URL="https://github.com/druidalabs/be.git"
WEBROOT="/var/www/bitcoinefectivo.com"
API_DIR="/home/bitcoinefectivo/be-backend"
BACKUP_DIR="/home/bitcoinefectivo/backups"

echo "Starting deployment..."

# Create backup
mkdir -p "$BACKUP_DIR"
if [ -d "$API_DIR" ]; then
    cp -r "$API_DIR" "$BACKUP_DIR/api-$(date +%Y%m%d-%H%M%S)"
fi

# Stop API service
sudo systemctl stop be-api

# Clone/update repository
if [ -d "/tmp/be" ]; then
    rm -rf /tmp/be
fi

git clone "$REPO_URL" /tmp/be

# Deploy website
cp -r /tmp/be/bitcoinefectivo/* "$WEBROOT/"

# Deploy API
cp -r /tmp/be/backend/* "$API_DIR/"

# Install dependencies
cd "$API_DIR"
npm install --production

# Copy install script to webroot
cp /tmp/be/scripts/install.sh "$WEBROOT/"

# Start API service
sudo systemctl start be-api
sudo systemctl status be-api

# Reload nginx
sudo systemctl reload nginx

echo "Deployment completed successfully!"
EOF

chmod +x /home/$USER/deploy.sh
chown "$USER:$USER" /home/$USER/deploy.sh

# Create backup script
cat > /home/$USER/backup.sh << 'EOF'
#!/bin/bash

# Bitcoin Efectivo Backup Script

BACKUP_DIR="/home/bitcoinefectivo/backups"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup API
tar -czf "$BACKUP_DIR/api-$DATE.tar.gz" -C /home/bitcoinefectivo be-backend

# Backup website
tar -czf "$BACKUP_DIR/website-$DATE.tar.gz" -C /var/www bitcoinefectivo.com

# Keep only last 7 days of backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /home/$USER/backup.sh
chown "$USER:$USER" /home/$USER/backup.sh

# Add cron job for daily backups
log_info "Setting up daily backups..."
(crontab -u "$USER" -l 2>/dev/null || echo "") | grep -v "backup.sh" | (cat; echo "0 2 * * * /home/$USER/backup.sh") | crontab -u "$USER" -

# Create status script
cat > /home/$USER/status.sh << 'EOF'
#!/bin/bash

echo "=== Bitcoin Efectivo Server Status ==="
echo

echo "System Information:"
echo "  Uptime: $(uptime)"
echo "  Load: $(cat /proc/loadavg)"
echo "  Memory: $(free -h | grep Mem: | awk '{print $3 "/" $2}')"
echo "  Disk: $(df -h / | tail -n1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
echo

echo "Services:"
echo "  nginx: $(systemctl is-active nginx)"
echo "  be-api: $(systemctl is-active be-api)"
echo "  fail2ban: $(systemctl is-active fail2ban)"
echo

echo "API Health:"
curl -s http://localhost:3000/health | python3 -m json.tool 2>/dev/null || echo "  API not responding"
echo

echo "Recent API logs:"
journalctl -u be-api --no-pager -n 5
EOF

chmod +x /home/$USER/status.sh
chown "$USER:$USER" /home/$USER/status.sh

# Install Go for building the CLI
log_info "Installing Go..."
GO_VERSION="1.21.0"
wget -q "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
rm "go${GO_VERSION}.linux-amd64.tar.gz"

# Add Go to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/$USER/.bashrc
echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc

log_success "Server setup completed!"
echo
echo "Next steps:"
echo "1. Configure your domain DNS to point to this server"
echo "2. Run: certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo "3. Copy the nginx configuration: cp /path/to/nginx.conf /etc/nginx/sites-available/$DOMAIN"
echo "4. Enable the site: ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/"
echo "5. Test nginx: nginx -t"
echo "6. Reload nginx: systemctl reload nginx"
echo "7. Run deployment: su - $USER -c './deploy.sh'"
echo
echo "Scripts available:"
echo "  /home/$USER/deploy.sh - Deploy latest version"
echo "  /home/$USER/backup.sh - Create backup"
echo "  /home/$USER/status.sh - Check system status"