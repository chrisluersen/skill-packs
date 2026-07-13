# Docker Setup: nesquena/hermes-webui on Windows

Session findings from setting up the third-party Hermes WebUI on Windows 10 with Docker Desktop.

## Key Paths (this user)

| Item | Path |
|------|------|
| Hermes home | `~/AppData/Local/hermes\AppData\Local\hermes` (or `~/AppData/Local/hermes/AppData/Local/hermes` in MSYS) |
| Docker | Desktop v29.5.2, WSL2 backend |
| Python | `~/AppData/Local/hermes\AppData\Local\hermes\hermes-agent\venv\Scripts\python.exe` |

## Docker Compose Configuration

From `docker-compose.yml` (master branch, commit b575252):

```yaml
services:
  hermes-webui:
    build: .
    ports:
      - "127.0.0.1:8787:8787"
    volumes:
      - ${HERMES_HOME:-${HOME}/.hermes}:/home/hermeswebui/.hermes
      - ${HERMES_WORKSPACE:-${HOME}/workspace}:/workspace
    environment:
      - WANTED_UID=${UID:-1000}
      - WANTED_GID=${GID:-1000}
      - HERMES_WEBUI_HOST=0.0.0.0
      - HERMES_WEBUI_PORT=8787
      - HERMES_WEBUI_STATE_DIR=/home/hermeswebui/.hermes/webui
      - HERMES_SKIP_CHMOD=1    # recommended on Windows
    restart: unless-stopped
```

## Multi-container variants

The repo also ships:
- `docker-compose.two-container.yml` — separate agent + webui containers
- `docker-compose.three-container.yml` — agent + webui + dashboard

## Permission Fixer

On first startup, the WebUI container runs a permission fixer that chmods the mounted `~/.hermes` directory. On Windows, this can clash with NTFS file modes. Set `HERMES_SKIP_CHMOD=1` to bypass it. Alternative: `HERMES_HOME_MODE=0640`.

## Memory usage comparison (from README)

| Method | RAM |
|--------|-----|
| Native Windows | ~330 MB |
| WSL2 + Docker | ~1080 MB |

## Image

Pre-built: `ghcr.io/nesquena/hermes-webui:latest` (amd64 + arm64)
