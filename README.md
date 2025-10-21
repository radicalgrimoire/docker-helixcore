*This README was generated and enhanced by AI.*

# Docker Helix Core (Perforce P4D Server)

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://github.com/radicalgrimoire/docker-helixcore/pkgs/container/docker-helixcore%2Fhelix-p4d)
[![Perforce](https://img.shields.io/badge/Perforce-Helix%20Core-blue?style=for-the-badge)](https://www.perforce.com/products/helix-core)

This is a Docker container for Perforce Helix Core (P4D) server prepared by radicalgrimoire(六魔辞典). The container includes automatic setup, security configurations, and useful triggers for production use.

Container images are available in GitHub Container Registry, so feel free to use them if you are interested.

## 🚀 Features

- **Ready-to-use Perforce Helix Core server** - Fully configured P4D instance
- **Japanese locale support** - Pre-configured for Japanese environment
- **Case sensitivity trigger** - Automatic case consistency checking
- **SSL/Security ready** - Configured with security best practices
- **Helix Authentication Extension** - Ready for SAML/OIDC integration
- **Log rotation** - Automated log management
- **Health checks** - Built-in container health monitoring
- **Persistent storage** - Data persists across container restarts

## 📋 Prerequisites

- Docker
- Docker Compose
- Make (optional, for using Makefile commands)

## 🔧 Quick Start

### Method 1: Using Docker Compose

```bash
docker-compose -f docker-compose.yml up -d
```

### Method 2: Using Makefile

```bash
# Start the container
make start

# Stop the container
make stop

# View logs
make logs

# Access container shell
make shell

# Build from source
make build

# Rebuild without cache
make rebuild

# Remove container and volumes
make remove
```

## 📁 Project Structure

```
docker-helixcore/
├── docker-compose.yml          # Docker Compose configuration
├── Makefile                    # Convenient make commands
├── README.md                   # This file
├── build/                      # Build context for creating images
│   ├── Dockerfile              # Main Dockerfile
│   ├── Dockerfile.v2           # Alternative Dockerfile with Swarm triggers
│   └── files/                  # Configuration and script files
│       ├── init.sh             # Initial setup script
│       ├── run.sh              # Container startup script
│       ├── CheckCaseTrigger*.py # Case sensitivity triggers
│       ├── P4Triggers.py       # Trigger helper library
│       ├── admin.txt           # Admin group configuration
│       ├── p4.*                # Logrotate configurations
│       └── get-keyvault-certificate.sh # Azure Key Vault integration
└── p4d/                        # Simple Dockerfile using pre-built image
    └── Dockerfile              # Uses GitHub Container Registry image
```

## ⚙️ Configuration

The container supports the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `P4NAME` | Perforce server name | - |
| `P4PORT` | Perforce server port | `ssl:1666` |
| `P4USER` | Administrative user | `super` |
| `P4PASSWD` | Administrative password | - |
| `P4HOME` | Perforce home directory | `/opt/perforce` |
| `P4ROOT` | Perforce root directory | - |
| `CASE_INSENSITIVE` | Case sensitivity setting | `0` (case-sensitive) |

### Network Configuration

The container uses a custom Docker network with the following settings:

- **Network**: `app_net` (172.16.238.0/24)
- **Container IP**: 172.16.238.10
- **Exposed Port**: 1666 (mapped to host port 1666)

## 🛠️ Container Access

### Access the running container

```bash
docker exec -it helix-p4d bash
```

### Using Makefile (Windows compatible)

```bash
make shell
```

## 🔒 Security Features

### SSL Configuration
- Pre-configured for SSL connections on port 1666
- Automatic trust establishment between server and clients

### Case Sensitivity Trigger
The container includes `CheckCaseTrigger3.py` which:
- Prevents file submissions with inconsistent case usage
- Maintains depot integrity across case-insensitive file systems
- Provides clear error messages for case conflicts

### Authentication Extension
- Includes Helix Authentication Extension for SAML/OIDC integration
- Ready for enterprise authentication systems

## 📊 Monitoring and Logs

### Health Checks
The container includes built-in health checks:
- Checks P4D server connectivity every 2 minutes
- 30-second timeout for health check operations

### Log Management
- Automatic log rotation configured
- Logs accessible via `docker-compose logs` or `make logs`
- Server logs located in `/opt/perforce/servers/[P4NAME]/logs/`

## 🔄 Data Persistence

The container uses Docker volumes to persist data:

```yaml
volumes:
  servers:  # Stores all Perforce server data
```

Server data is stored in `/opt/perforce/servers` and persists across container restarts and updates.

## 🏗️ Building from Source

### Build the main image

```bash
docker-compose -f docker-compose.yml build
```

### Build with no cache

```bash
make rebuild
```

### Build arguments

The Dockerfile supports various build arguments for customization. See the Dockerfile for complete list of available arguments.

## 🚦 Usage Examples

### Connect with P4V (Perforce Visual Client)

1. Server: `ssl:localhost:1666` (or your server's IP)
2. Username: `super` (or configured P4USER)
3. Password: As configured in P4PASSWD

### Command Line Operations

```bash
# Connect to server
p4 -p ssl:localhost:1666 -u super login

# Create a new workspace
p4 client my-workspace

# Add files to depot
p4 add file.txt
p4 submit -d "Initial commit"
```

## 🐛 Troubleshooting

### Common Issues

1. **Container won't start**
   - Check if port 1666 is available
   - Verify Docker and Docker Compose are installed
   - Check container logs: `make logs`

2. **SSL Connection Issues**
   - Ensure you're connecting to `ssl:1666` not just `1666`
   - Trust the server certificate when prompted

3. **Permission Issues**
   - Verify container has proper permissions to write to volumes
   - Check if SELinux or similar security modules are interfering

### Logs and Debugging

```bash
# View container logs
make logs

# Access container for debugging
make shell

# Check Perforce server status inside container
p4dctl status
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 👤 Maintainer

**ueno.s** `<ueno.s@gamestudio.co.jp>`

## 🔗 Links

- [Perforce Helix Core Documentation](https://www.perforce.com/manuals/p4sag/)
- [Docker Hub Repository](https://github.com/radicalgrimoire/docker-helixcore/pkgs/container/docker-helixcore%2Fhelix-p4d)
- [Perforce Helix Authentication Extension](https://github.com/perforce/helix-authentication-extension)

---

**Note**: This container is designed for development and testing purposes. For production deployments, please review and adjust security settings, networking, and backup strategies according to your organization's requirements.
