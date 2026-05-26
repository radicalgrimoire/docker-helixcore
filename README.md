# Docker Helix Core

This repository runs a Perforce Helix Core (P4D) server in a Docker container.  
The current standard startup flow uses an existing image referenced by p4d/Dockerfile and starts it through docker-compose.yml.

## Overview

- Helix Core container environment for development and validation
- SSL-based configuration on port 1666
- Startup health check included
- Uses an image that contains the case-consistency trigger, CheckCaseTrigger3.py
- Data is persisted in the Docker volume named servers

## Current Layout

Main files:

- docker-compose.yml: Container startup settings for helix-p4d
- Makefile: Main operational commands for start, stop, logs, shell, and build
- p4d/Dockerfile: Runtime image based on ghcr.io/radicalgrimoire/docker-helixcore/helix-p4d:latest
- build/Dockerfile: Definition used to rebuild the base image yourself
- build/files/init.sh: Initial setup for server and trigger configuration
- build/files/run.sh: Server startup and log output

Network and port settings in docker-compose.yml:

- Custom network: app_net (172.16.238.0/24)
- Container IP: 172.16.238.10
- Published port: 1666:1666

## Prerequisites

- Docker
- Docker Compose
- Make if you want to use the Makefile
- winpty on Windows if you want to use make shell

## Quick Start

| Step | Action | Command |
| --- | --- | --- |
| 1 | Start | `make start` |
| 1 (alternative) | Start | `docker-compose -f docker-compose.yml -p helixcore up -d` |
| 2 | View Logs | `make logs` |
| 3 | Open a Shell | `make shell` |
| 4 | Stop | `make stop` |
| 5 | Remove the Container | `make remove` |

## Makefile Commands

- make start: Start the container
- make stop: Stop the container
- make remove: Run docker-compose down
- make logs: Follow container logs
- make shell: Open a shell inside the container
- make build: Build the image
- make rebuild: Rebuild without cache

## Environment Variables

Main environment variables used by this project:

| Variable | Description | Example value |
| --- | --- | --- |
| P4NAME | Perforce server name | Any value |
| P4PORT | Perforce server port | ssl:1666 |
| P4USER | Administrator user | super |
| P4PASSWD | Administrator password | Any value |
| P4HOME | Perforce home directory | /opt/perforce |
| P4ROOT | Perforce root directory | Example: /opt/perforce/servers/your-server/root |
| CASE_INSENSITIVE | Case-sensitivity setting | 0 |

Notes:

- The current docker-compose.yml does not declare environment variables explicitly.
- Default behavior depends on the referenced image configuration.
- If you want to pin values, add them under services.helixcore.environment in docker-compose.yml.

Example:

```yaml
services:
  helixcore:
    environment:
      P4NAME: helix
      P4PORT: ssl:1666
      P4USER: super
      P4PASSWD: your-password
```

## Data Persistence

- Volume: servers
- Mount point: /opt/perforce/servers

Data is preserved across container recreation unless you delete the volume.

## Password Management Policy

This image does not rotate the super password automatically.
The administrator user `super` is not intended to have its password changed during normal operation. If you change it, do so at your own responsibility.

Use your operational process to manage and rotate credentials.
At startup, the container attempts login with P4PASSWD and proceeds even if login fails in an existing environment.

## Connecting

Example connection settings for P4V or the CLI:

- Server: ssl:localhost:1666
- User: super or the user you configured
- Password: your configured value

CLI example:

```bash
p4 -p ssl:localhost:1666 -u super login
```

## Custom Builds

For standard usage, the prebuilt-image flow through p4d/Dockerfile is usually sufficient.  
Use build/ only when you need to create a custom image.

```bash
make build
make rebuild
```

Or:

```bash
bash build/docker-build.sh Dockerfile ./build
```

## Troubleshooting

### Startup Fails

- Check whether port 1666 is already in use
- Review errors with make logs
- Check container state with docker ps -a

### Cannot Connect

- Verify that the target server is ssl:localhost:1666
- Certificate trust may be required on the first connection

### Check Status

```bash
make shell
p4dctl status
```

## References

- [Perforce Helix Core documentation](https://www.perforce.com/manuals/p4sag/)
- [Container image](https://github.com/radicalgrimoire/docker-helixcore/pkgs/container/docker-helixcore%2Fhelix-p4d)
- [Helix Authentication Extension](https://github.com/perforce/helix-authentication-extension)

## Notes

This setup is intended for development and validation use.  
For production use, design authentication and authorization, network restrictions, backup, monitoring, and certificate operations separately.
