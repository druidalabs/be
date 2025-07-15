# Backend Installation Guide

## Quick Fix for Node.js Installation Issues

If you encounter Node.js installation conflicts, run:

```bash
sudo ./scripts/fix-nodejs.sh
```

## Manual Installation Steps

### 1. Fix Node.js Installation Conflicts

```bash
# Remove conflicting packages
sudo apt remove --purge -y nodejs npm libnode-dev node-gyp
sudo apt autoremove -y

# Clean up leftover files
sudo rm -rf /usr/lib/node_modules
sudo rm -rf /usr/include/node
sudo rm -f /usr/bin/node
sudo rm -f /usr/bin/npm
```

### 2. Install Node.js (Choose one method)

**Method A: Using NodeSource Repository**
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
sudo apt install -y --force-overwrite nodejs
```

**Method B: Using Snap**
```bash
sudo snap install node --classic
sudo ln -sf /snap/bin/node /usr/local/bin/node
sudo ln -sf /snap/bin/npm /usr/local/bin/npm
```

**Method C: Using NVM (Node Version Manager)**
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 18
nvm use 18
nvm alias default 18
```

### 3. Verify Installation

```bash
node --version  # Should show v18.x.x
npm --version   # Should show 9.x.x or higher
```

### 4. Install Backend Dependencies

```bash
cd /path/to/be/backend
npm install
```

### 5. Configure Environment

```bash
cp .env.example .env
# Edit .env with your configuration
nano .env
```

### 6. Start the Backend

```bash
# Development mode
npm run dev

# Production mode
npm start
```

### 7. Create Systemd Service (Production)

```bash
sudo cp /path/to/be/backend/be-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable be-api
sudo systemctl start be-api
```

## Troubleshooting

### Common Issues

1. **EACCES permissions error**
   ```bash
   sudo chown -R $(whoami) ~/.npm
   ```

2. **Port already in use**
   ```bash
   sudo lsof -i :3000
   sudo kill -9 <PID>
   ```

3. **Permission denied on /usr/local/bin**
   ```bash
   sudo mkdir -p /usr/local/bin
   sudo chown -R $(whoami) /usr/local
   ```

### Verify Backend is Running

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "version": "1.0.0"
}
```

## Security Considerations

- Always use a strong JWT secret in production
- Configure firewall to only allow necessary ports
- Use HTTPS in production
- Set up proper logging and monitoring
- Regular security updates

## Performance Optimization

- Use PM2 for process management in production
- Configure nginx for load balancing
- Set up Redis for rate limiting
- Monitor memory usage and optimize as needed