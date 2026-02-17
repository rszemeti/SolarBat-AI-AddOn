#!/usr/bin/env bash
# bootstrap.sh - Download/update SolarBat-AI app code from the main repo
set -e

REPO="rszemeti/SolarBat-AI"
APP_DIR="/app/apps/solar_optimizer"
VERSION_FILE="/data/.installed_version"
CONFIG_DIR="/config"

echo "[SolarBat-AI] Bootstrap starting..."

# Get latest release tag from GitHub
echo "[SolarBat-AI] Checking for latest release..."
LATEST=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | jq -r '.tag_name // empty')

if [ -z "$LATEST" ]; then
    echo "[SolarBat-AI] No releases found, using main branch"
    LATEST="main"
    DOWNLOAD_URL="https://github.com/${REPO}/archive/refs/heads/main.zip"
else
    echo "[SolarBat-AI] Latest release: ${LATEST}"
    DOWNLOAD_URL="https://github.com/${REPO}/archive/refs/tags/${LATEST}.zip"
fi

# Check if we already have this version
INSTALLED=$(cat "$VERSION_FILE" 2>/dev/null || echo "none")
if [ "$INSTALLED" = "$LATEST" ] && [ -f "$APP_DIR/solar_optimizer.py" ]; then
    echo "[SolarBat-AI] Already running ${LATEST}, skipping download"
    return 0 2>/dev/null || exit 0
fi

# Download and extract
echo "[SolarBat-AI] Downloading ${LATEST}..."
TMPDIR=$(mktemp -d)
curl -sL "$DOWNLOAD_URL" -o "$TMPDIR/solarbat.zip"

if [ ! -f "$TMPDIR/solarbat.zip" ]; then
    echo "[SolarBat-AI] Error: Download failed"
    exit 1
fi

cd "$TMPDIR"
unzip -q solarbat.zip

# Find the extracted directory (GitHub adds repo-branch prefix)
EXTRACTED=$(find . -maxdepth 1 -type d -name "SolarBat-AI*" | head -1)
if [ -z "$EXTRACTED" ]; then
    echo "[SolarBat-AI] Error: Could not find extracted files"
    rm -rf "$TMPDIR"
    exit 1
fi

# Install app code
echo "[SolarBat-AI] Installing app code to ${APP_DIR}..."
mkdir -p "$APP_DIR"
rm -rf "$APP_DIR"/*
cp -r "$EXTRACTED/apps/solar_optimizer/"* "$APP_DIR/"

# Copy template apps.yaml to config if it doesn't exist
if [ ! -f "$CONFIG_DIR/apps.yaml" ]; then
    echo "[SolarBat-AI] Creating template apps.yaml in ${CONFIG_DIR}..."
    if [ -f "$APP_DIR/apps.yaml.example" ]; then
        cp "$APP_DIR/apps.yaml.example" "$CONFIG_DIR/apps.yaml"
        # Add template marker
        echo -e "\n# Template: True  # <-- Remove this line once you have configured apps.yaml" >> "$CONFIG_DIR/apps.yaml"
    fi
fi

# Record installed version
echo "$LATEST" > "$VERSION_FILE"

# Cleanup
rm -rf "$TMPDIR"

echo "[SolarBat-AI] Installed version ${LATEST} successfully"
