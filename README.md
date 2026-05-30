# go-limit

A bash script that automatically calculates and sets optimal memory limits for your Docker containers and Go applications based on available host RAM.

## What It Does

The script reads the host's total RAM and sets:

- **Docker container memory limit** — 85% of host RAM (via `deploy.resources.limits.memory` in `docker-compose.yml`)
- **Go `GOMEMLIMIT`** — 75% of host RAM (via `environment` in `docker-compose.yml`)

This helps prevent out-of-memory issues while leaving enough headroom for the host OS.

## Prerequisites

- **Linux** (requires `/proc/meminfo`)
- **Docker** and **Docker Compose** installed
- **`perl`** and **`sed`** (typically pre-installed on most Linux systems)
- A `docker-compose.yml` file in the current directory

## Quick Start (One Command)

Run directly from GitHub — no need to clone or download anything:

```bash
cd /opt/remnanode/
sudo bash <(curl -s https://raw.githubusercontent.com/raaad1on/go-limit/main/set-memory-limits.sh?t=$(date +%s))
```

## Usage (Manual)

1. Place the script in the same directory as your `docker-compose.yml`:

   ```bash
   cp set-memory-limits.sh /opt/remnawave/
   cd /opt/remnawave
   ```

2. Make the script executable:

   ```bash
   chmod +x set-memory-limits.sh
   ```

3. Run it:

   ```bash
   sudo ./set-memory-limits.sh
   ```

4. The script will display the detected RAM and calculated limits, then ask whether to restart the containers.

## Example Output

```
--- Setting memory limits ---
Host RAM: 16 GB
Will set: Docker Memory: 13G, GOMEMLIMIT: 12GiB

Limits written to docker-compose.yml successfully.
Applied values:
      GOMEMLIMIT: "12GiB"
          memory: 13G
Restart containers now? (y/n):
```

## How It Works

1. Reads total host RAM from `/proc/meminfo`
2. Calculates 85% for Docker and 75% for Go memory limits
3. Adds or updates the `GOMEMLIMIT` variable in the `environment` section of `docker-compose.yml`
4. Adds or updates the `deploy.resources.limits.memory` section in `docker-compose.yml`
5. Optionally restarts the Docker Compose stack to apply changes

## Notes

- The script is designed for **Linux only** (`/proc/meminfo` is not available on macOS)
- If the `deploy` section doesn't exist in your `docker-compose.yml`, it will be created automatically
- Existing values are replaced; new values are inserted if missing
