# Docker Helix Core

This repository runs Perforce Helix Core (P4D) in a Docker container.  
It is primarily intended for development and validation, and starts the helix-p4d container from docker-compose.yml.

## Overview

- Exposes port 1666 over SSL
- Persists server data in the Docker volume named servers
- Uses a custom network app_net with subnet 172.16.238.0/24
- Includes a health check that runs p4 -p ssl:1666 info -s
- Uses the case consistency trigger script CheckCaseTrigger3.py on change submit

## Repository Structure

- docker-compose.yml: Service definition for helixcore
- Makefile: Daily operation commands
- p4d/Dockerfile: Runtime Dockerfile based on ghcr.io/radicalgrimoire/docker-helixcore/helix-p4d:latest
- p4d/download-certs.sh: Helper script to download certificate archives from GitHub Releases
- build/Dockerfile: Dockerfile for rebuilding the base image
- build/docker-build.sh: Build wrapper that assembles --build-arg values from .env and environment variables
- build/files/init.sh: First-time initialization logic (server setup, login, trigger registration)
- build/files/run.sh: Startup logic (start server, login attempt, log tailing)

## Prerequisites

- Docker
- Docker Compose (docker-compose command)
- GNU Make (make)
- winpty on Windows if you use make shell

## Quick Start

| Step | Command | Description |
| --- | --- | --- |
| 1 | `make start` | Start the Helix Core container in detached mode. |
| 2 | `make logs` | Follow container logs to confirm startup and runtime status. |
| 3 | `make shell` | Open an interactive shell inside the running container. |
| 4 | `make stop` | Stop the running container without removing it. |
| 5 | `make remove` | Remove the container and network created by docker-compose down. |

Direct docker-compose command:

```bash
docker-compose -f docker-compose.yml -p helixcore up -d
```

## Makefile Commands

- make start: Start containers
- make stop: Stop containers
- make remove: Run docker-compose down
- make logs: Follow logs
- make shell: Open bash in the container
- make build: Build image from compose definition
- make rebuild: Rebuild without cache
- make change-password: Change the super user password

Example for change-password:

```bash
OLD_PASS=<current-password> NEW_PASS=<new-password> make change-password
```

After changing the password, update P4PASSWD in your compose, env, or secret settings before restart.

## Network and Persistence

- Container name: helix-p4d
- Static IP: 172.16.238.10
- Published port: 1666:1666
- Volume: servers:/opt/perforce/servers

Data remains available across container recreation unless you remove the volume.

## Environment Variables

Main variables used by this project:

| Variable | Description | Example |
| --- | --- | --- |
| P4NAME | Perforce server name | master |
| P4PORT | Server port | ssl:1666 |
| P4USER | Admin user | super |
| P4PASSWD | Admin password | any secure value |
| P4HOME | Perforce home | /opt/perforce/servers |
| P4ROOT | Server root | /opt/perforce/servers/master |
| CASE_INSENSITIVE | Case mode (0 = case-sensitive, 1 = case-insensitive) | 0 |
| P4CONFIG | p4 config path | /opt/perforce/.p4config |

Notes:

- The current docker-compose.yml does not explicitly define environment values.
- Effective values depend on the base image configuration and build args.
- To pin values, add services.helixcore.environment in docker-compose.yml.

Example:

```yaml
services:
  helixcore:
    environment:
      P4NAME: master
      P4PORT: ssl:1666
      P4USER: super
      P4PASSWD: your-password
      P4ROOT: /opt/perforce/servers/master
      CASE_INSENSITIVE: 0
```

## Building Images

For standard operation, the image referenced by p4d/Dockerfile is sufficient.  
Use build/ when you need to rebuild a custom base image.

```bash
make build
make rebuild
```

Or:

```bash
bash build/docker-build.sh Dockerfile ./build
```

build/docker-build.sh passes these values as --build-arg:

- Variables defined in build/.env
- Runtime environment variables (P4NAME, P4PORT, P4USER, P4PASSWD, P4HOME, P4ROOT, CASE_INSENSITIVE)

## Startup Behavior

build/files/init.sh (first-time configuration) mainly does the following:

- Initializes the server with configure-helix-p4d.sh
- Runs p4 trust and p4 login
- Sets server configuration values such as server.extensions.allow.unsigned
- Registers trigger:
  - CheckCaseTrigger change-submit //... "python3 /usr/local/bin/CheckCaseTrigger3.py %changelist% port=ssl:1666 user=super"
- Imports admin group definition from admin.txt

build/files/run.sh (every startup) mainly does the following:

- Starts the server with p4dctl start -t p4d ${P4NAME}
- Starts cron
- Attempts login using P4PASSWD
- Rewrites P4CONFIG only when login succeeds
- Tails P4ROOT/logs/log

If P4PASSWD does not match the actual server password in an existing volume, startup continues but automatic login fails.
The administrator user super is not intended to have its password changed during normal operation. If you change it, do so at your own responsibility.

## Connection Example

For both P4V and CLI:

- Server: ssl:localhost:1666
- User: super (or your configured user)
- Password: the value currently configured on the server

CLI:

```bash
p4 -p ssl:localhost:1666 -u super login
```

## Certificate Download Helper

p4d/download-certs.sh downloads and extracts certificate archives from GitHub Releases.

```bash
bash p4d/download-certs.sh --help
```

Main options:

- -r, --repo: Repository in owner/repository format
- -t, --token: GitHub token
- -d, --dir: Download directory
- -y, --yes: Skip confirmation prompts

## CI/CD Workflows

The .github/workflows directory includes:

- build-test.yml: Build and basic plus integration tests for branches
- build-develop.yml: Scheduled or manual pipeline from test to publish
- test.yml: Reusable test workflow
- get-version.yml: Extracts p4d -V from built image artifact
- publish.yml: Publishes tagged images to GHCR

Main publish tags:

- <version>.<run_number>
- latest
- nightly (only on scheduled runs)

## Troubleshooting

If startup fails:

- Check whether port 1666 is already in use
- Check errors with make logs
- Check container state with docker ps -a

If connection fails:

- Verify target server is ssl:localhost:1666
- First connection may require p4 trust

Server status check example:

```bash
make shell
p4dctl status
```

## References

- Perforce Helix Core Documentation: https://www.perforce.com/manuals/p4sag/
- Container Image: https://github.com/radicalgrimoire/docker-helixcore/pkgs/container/docker-helixcore%2Fhelix-p4d
- Helix Authentication Extension: https://github.com/perforce/helix-authentication-extension

## Notes

This setup is intended for development and validation.  
For production, at minimum, design and validate:

- Authentication and authorization
- Network restrictions
- Backup and restore procedures
- Monitoring and alerting
- Certificate distribution and rotation
