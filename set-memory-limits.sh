#!/bin/bash

if [ -f "docker-compose.yml" ]; then
    FILE="docker-compose.yml"
elif [ -f "compose.yml" ]; then
    FILE="compose.yml"
else
    echo "Error: Neither docker-compose.yml nor compose.yml found!" && exit 1
fi

# 1. Calculations
TOTAL_RAM_MB=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
DOCKER_LIMIT_GB=$((TOTAL_RAM_MB * 85 / 100 / 1024))
GO_LIMIT_GB=$((TOTAL_RAM_MB * 75 / 100 / 1024))

echo "--- Setting memory limits ---"
echo "Host RAM: $((TOTAL_RAM_MB / 1024)) GB"
echo "Will set: Docker Memory: ${DOCKER_LIMIT_GB}G, GOMEMLIMIT: ${GO_LIMIT_GB}GiB"

# 2. Safe replace/insert function (preserves indentation)
update_yaml() {
    local key=$1
    local value=$2
    local indent=$3
    if grep -q "^[[:space:]]*$key:" "$FILE"; then
        perl -i -pe "s/^([[:space:]]*)$key: .*/\$1$key: $value/" "$FILE"
    else
        sed -i "/^[[:space:]]*environment:/a \\$indent$key: $value" "$FILE"
    fi
}

# Update GOMEMLIMIT (inside environment)
update_yaml "GOMEMLIMIT" "\"${GO_LIMIT_GB}GiB\"" "      "

# 3. Handle deploy section
# First, check if a valid memory line already exists inside deploy
if perl -0777 -ne 'exit !(/deploy:.*?memory:\s*\d+G/s)' "$FILE"; then
    # Simple case: just update the existing value
    # BUG FIX: ${1} instead of $1 to avoid perl interpreting e.g. $113 as backreference to group 113
    perl -i -pe "s/(memory: )\d+G/\${1}${DOCKER_LIMIT_GB}G/" "$FILE"
else
    # Deploy block is missing or malformed — remove it and re-add cleanly
    # Remove any existing deploy block (from "deploy:" through deeper-indented lines)
    perl -0777 -i -pe 's/^[ \t]*deploy:\n(?:[ \t]+.*\n)*//m' "$FILE"
    # Insert fresh deploy block after container_name line
    perl -0777 -i -pe "s/(container_name:.*\n)/\$1    deploy:\n      resources:\n        limits:\n          memory: ${DOCKER_LIMIT_GB}G\n/" "$FILE"
fi

# 4. Verification and restart
echo -e "\nLimits written to $FILE successfully."
echo "Applied values:"
grep -E "memory:|GOMEMLIMIT:" "$FILE"

read -p "Restart containers now? (y/n): " confirm
if [[ $confirm == [yY] ]]; then
    echo "Running docker compose down && up -d..."
    docker compose down && docker compose up -d
    echo "Done."
else
    echo "Restart cancelled. Limits will apply on next docker compose up."
fi