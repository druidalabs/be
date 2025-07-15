# Bitcoin Efectivo CLI

A lightweight, open-source CLI tool for interacting with the Bitcoin Efectivo network. Install with a single command and start using Bitcoin directly from your terminal.

## 🚀 Quick Start

### Installation

**One-liner installation:**
```bash
curl -sSL https://bitcoinefectivo.com/install.sh | bash
```

**Manual installation:**
1. Download the latest release from [GitHub Releases](https://github.com/druidalabs/be/releases/latest)
2. Make it executable: `chmod +x be`
3. Move to your PATH: `sudo mv be /usr/local/bin/`

### Usage

```bash
# Show help
be --help

# Create account and get API token
be signup

# Check account status
be status

# Send Bitcoin Efectivo
be send 100000 bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh

# Send with message
be send 100000 bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh --message "Payment for services"
```

## 📋 Features

- **Secure Authentication**: Token-based authentication stored locally
- **Rate Limited**: Protected against abuse with intelligent rate limiting
- **Cross-Platform**: Works on Linux, macOS, and Windows
- **Lightweight**: Single binary with no dependencies
- **Open Source**: MIT licensed and fully transparent

## 🔧 Configuration

The CLI stores configuration in `~/.be/config.json`:

```json
{
  "api_token": "your-secure-token",
  "api_url": "https://api.bitcoinefectivo.com",
  "user_id": "your-user-id",
  "expires_at": "2024-01-01T00:00:00Z",
  "created_at": "2023-12-01T00:00:00Z",
  "last_used": "2023-12-01T00:00:00Z"
}
```

## 🏗️ Development

### Prerequisites

- Go 1.21 or later
- Node.js 18 or later (for backend development)

### Building from Source

```bash
# Clone the repository
git clone https://github.com/druidalabs/be.git
cd be

# Build the CLI
go build -o be .

# Install dependencies and start backend (for development)
cd backend
npm install
npm run dev
```

### Project Structure

```
be/
├── cmd/                 # CLI commands
│   ├── root.go         # Root command configuration
│   ├── signup.go       # Signup command
│   ├── status.go       # Status command
│   └── send.go         # Send command
├── internal/           # Internal packages
│   └── config/         # Configuration management
├── pkg/                # Public packages
│   ├── client/         # API client
│   └── types/          # Type definitions
├── backend/            # Node.js API backend
│   ├── routes/         # API routes
│   ├── middleware/     # Express middleware
│   └── models/         # Data models
├── scripts/            # Deployment scripts
└── .github/            # GitHub Actions workflows
```

## 🌐 API Endpoints

The backend provides versioned RESTful API endpoints:

- `POST /api/v1/signup` - Create account and get token
- `GET /api/v1/status` - Check account status
- `POST /api/v1/send` - Send transaction
- `GET /api/v1/balance` - Get account balance

All endpoints (except signup) require Bearer token authentication.

## 🔒 Security

- **Token Expiration**: API tokens expire after 30 days
- **Rate Limiting**: Multiple layers of rate limiting prevent abuse
- **Browser Blocking**: API blocks browser requests to prevent CSRF
- **HTTPS Only**: All API communication is encrypted
- **Local Storage**: Tokens stored securely in local filesystem

## 📊 Rate Limits

| Endpoint | Limit | Window |
|----------|-------|---------|
| Global | 100 requests | 15 minutes |
| Signup | 5 requests | 1 hour |
| Authenticated | 30 requests | 1 minute |
| Send | 10 requests | 1 minute |

## 🚀 Deployment

### Server Setup

1. Run the server setup script:
```bash
sudo ./scripts/server-setup.sh
```

2. Configure SSL with Let's Encrypt:
```bash
sudo certbot --nginx -d bitcoinefectivo.com -d www.bitcoinefectivo.com
```

3. Configure nginx:
```bash
sudo cp scripts/nginx.conf /etc/nginx/sites-available/bitcoinefectivo.com
sudo ln -s /etc/nginx/sites-available/bitcoinefectivo.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

4. Deploy the application:
```bash
sudo su - bitcoinefectivo
./deploy.sh
```

### Environment Variables

```bash
NODE_ENV=production
PORT=3000
JWT_SECRET=your-super-secret-jwt-key
CORS_ORIGIN=https://bitcoinefectivo.com
```

## 📝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 🐛 Bug Reports

Please use the [GitHub Issues](https://github.com/druidalabs/be/issues) page to report bugs or request features.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Cobra](https://github.com/spf13/cobra) for CLI framework
- Powered by [Express.js](https://expressjs.com/) for the backend
- Inspired by the Bitcoin development community

## 🔗 Links

- **Website**: [bitcoinefectivo.com](https://bitcoinefectivo.com)
- **GitHub**: [github.com/druidalabs/be](https://github.com/druidalabs/be)
- **Issues**: [github.com/druidalabs/be/issues](https://github.com/druidalabs/be/issues)

---

Made with ❤️ for the Bitcoin development community.