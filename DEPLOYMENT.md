# Bitcoin Efectivo CLI - Deployment Guide

## Prerequisites

Before deploying, ensure you have:
- GitHub repository created and configured
- Go 1.21+ installed for building
- Domain name pointing to your server
- SSL certificate (Let's Encrypt recommended)

## Deployment Steps

### 1. Create GitHub Repository

```bash
# Create a new repository on GitHub: druidalabs/be
# Clone and push the code
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/druidalabs/be.git
git push -u origin main
```

### 2. Create Initial Release

```bash
# Create and push a tag to trigger the release workflow
git tag v0.1.0
git push origin v0.1.0
```

This will trigger the GitHub Actions workflow that builds cross-platform binaries.

### 3. Test Installation Script (After Release)

```bash
# Test the installation script
curl -sSL https://raw.githubusercontent.com/druidalabs/be/main/scripts/install.sh | bash
```

### 4. Local Development Testing

If you want to test before creating a release:

```bash
# Build locally
./scripts/build-local.sh

# Test the CLI
be --help
be --version
```

### 5. Server Setup

```bash
# On your server, run the setup script
sudo ./scripts/server-setup.sh
```

If you encounter Node.js installation issues:

```bash
# Fix Node.js conflicts
sudo ./scripts/fix-nodejs.sh
```

### 6. Deploy Backend

```bash
# Deploy the backend application
sudo su - bitcoinefectivo
./deploy.sh
```

### 7. Configure Web Server

```bash
# Copy nginx configuration
sudo cp scripts/nginx.conf /etc/nginx/sites-available/bitcoinefectivo.com
sudo ln -s /etc/nginx/sites-available/bitcoinefectivo.com /etc/nginx/sites-enabled/

# Test and reload nginx
sudo nginx -t
sudo systemctl reload nginx
```

### 8. Deploy Website and Install Script

```bash
# Copy website files
sudo cp -r bitcoinefectivo/* /var/www/bitcoinefectivo.com/

# Copy install script
sudo cp scripts/install.sh /var/www/bitcoinefectivo.com/

# Set proper permissions
sudo chown -R www-data:www-data /var/www/bitcoinefectivo.com
```

### 9. Configure SSL Certificate

```bash
# Get Let's Encrypt certificate
sudo certbot --nginx -d bitcoinefectivo.com -d www.bitcoinefectivo.com
```

## Testing the Full Flow

### 1. Test Website
Visit https://bitcoinefectivo.com and verify:
- Terminal interface works
- `install` command shows CLI information
- All existing commands work

### 2. Test CLI Installation
```bash
curl -sSL https://bitcoinefectivo.com/install.sh | bash
```

### 3. Test CLI Commands
```bash
be --help
be signup
be status
be send 1000 bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh
```

### 4. Test Backend API
```bash
# Health check
curl https://bitcoinefectivo.com/health

# Test signup (should work)
curl -X POST https://bitcoinefectivo.com/api/v1/signup \
  -H "Content-Type: application/json" \
  -H "User-Agent: be-cli/1.0" \
  -d '{"username": "testuser", "email": "test@example.com"}'

# Test browser blocking (should fail)
curl -X POST https://bitcoinefectivo.com/api/v1/signup \
  -H "Content-Type: application/json" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
  -d '{"username": "testuser", "email": "test@example.com"}'
```

## Troubleshooting

### Common Issues

1. **GitHub release not found**
   - Ensure you've pushed a tag: `git tag v0.1.0 && git push origin v0.1.0`
   - Check GitHub Actions workflow completed successfully
   - Verify releases are published at https://github.com/druidalabs/be/releases

2. **Installation script fails**
   - Check if the binary exists in the release
   - Verify download URL format in install.sh
   - Test with curl: `curl -I https://github.com/druidalabs/be/releases/download/v0.1.0/be-darwin-amd64`

3. **CLI binary not working**
   - Check if Go dependencies are properly vendored
   - Verify build flags in GitHub Actions
   - Test local build: `go build -o be . && ./be --version`

4. **Backend API not responding**
   - Check service status: `sudo systemctl status be-api`
   - View logs: `sudo journalctl -u be-api -f`
   - Test local connection: `curl localhost:3000/health`

5. **Website not loading**
   - Check nginx configuration: `sudo nginx -t`
   - Verify SSL certificate: `sudo certbot certificates`
   - Check file permissions: `ls -la /var/www/bitcoinefectivo.com/`

### Debug Commands

```bash
# Check server status
./status.sh

# View API logs
sudo journalctl -u be-api -f

# Test nginx configuration
sudo nginx -t

# Check firewall
sudo ufw status

# Check SSL certificate
sudo certbot certificates

# Test DNS resolution
dig bitcoinefectivo.com
```

## Rollback Procedure

If something goes wrong:

```bash
# Stop services
sudo systemctl stop be-api
sudo systemctl stop nginx

# Restore from backup
sudo tar -xzf /home/bitcoinefectivo/backups/api-YYYYMMDD-HHMMSS.tar.gz -C /home/bitcoinefectivo/
sudo tar -xzf /home/bitcoinefectivo/backups/website-YYYYMMDD-HHMMSS.tar.gz -C /var/www/

# Restart services
sudo systemctl start be-api
sudo systemctl start nginx
```

## Monitoring

Set up monitoring for:
- API health endpoint
- Service status
- Disk usage
- Error logs
- SSL certificate expiration

Consider using tools like:
- Uptime Robot for external monitoring
- Log aggregation for error tracking
- Backup verification scripts

## Security Checklist

- [ ] SSL certificate installed and auto-renewal configured
- [ ] Firewall configured (only SSH, HTTP, HTTPS open)
- [ ] Fail2ban configured for SSH protection
- [ ] Regular security updates scheduled
- [ ] Strong JWT secret configured
- [ ] Rate limiting properly configured
- [ ] Browser requests blocked for API endpoints
- [ ] Regular backups automated and tested

## Performance Optimization

- [ ] Nginx gzip compression enabled
- [ ] Static asset caching configured
- [ ] API response caching where appropriate
- [ ] Database connection pooling (when database is added)
- [ ] CDN setup for static assets (optional)
- [ ] Load balancing setup (for high traffic)

## Next Steps

After successful deployment:
1. Set up monitoring and alerting
2. Configure regular backups
3. Plan for database migration (from in-memory to persistent storage)
4. Set up CI/CD pipeline for automated deployments
5. Add more CLI commands as needed
6. Scale infrastructure based on usage