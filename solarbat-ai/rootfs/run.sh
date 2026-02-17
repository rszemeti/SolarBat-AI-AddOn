#!/usr/bin/env bash
# run.sh - SolarBat-AI addon entrypoint
# Option 1: Runs AppDaemon internally with our app code
# Option 2 (future): Replace with direct HA websocket launcher
set -e

CONFIG_DIR="/config"
APP_DIR="/app"
DATA_DIR="/data"

echo "============================================="
echo " SolarBat-AI - Solar Battery Optimizer"
echo "============================================="

# ── Step 1: Bootstrap / update app code from main repo ──
echo "[SolarBat-AI] Checking for app updates..."
bash /bootstrap.sh || echo "[SolarBat-AI] Warning: Bootstrap failed, using existing code"

# ── Step 2: Check apps.yaml exists and isn't template ──
if [ ! -f "$CONFIG_DIR/apps.yaml" ]; then
    echo "[SolarBat-AI] Error: No apps.yaml found in $CONFIG_DIR"
    echo "[SolarBat-AI] Please configure apps.yaml - see documentation"
    echo "[SolarBat-AI] A template has been created for you to edit"
    sleep 300
    exit 1
fi

if grep -q "^# Template: True" "$CONFIG_DIR/apps.yaml" 2>/dev/null || \
   grep -q "^Template: True" "$CONFIG_DIR/apps.yaml" 2>/dev/null; then
    echo "[SolarBat-AI] Error: Template apps.yaml detected"
    echo "[SolarBat-AI] Please edit $CONFIG_DIR/apps.yaml with your sensor entity IDs"
    echo "[SolarBat-AI] Then remove the 'Template: True' line to start"
    sleep 300
    exit 1
fi

# ── Step 3: Get HA connection details from Supervisor ──
HA_TOKEN="${SUPERVISOR_TOKEN}"
HA_URL="http://supervisor/core"

echo "[SolarBat-AI] DEBUG: HA_URL=${HA_URL}"
echo "[SolarBat-AI] DEBUG: SUPERVISOR_TOKEN length=${#HA_TOKEN}"
echo "[SolarBat-AI] DEBUG: SUPERVISOR_TOKEN first 20 chars=${HA_TOKEN:0:20}..."

if [ -z "$HA_TOKEN" ]; then
    echo "[SolarBat-AI] Warning: No SUPERVISOR_TOKEN, trying ha_url/ha_key from apps.yaml"
fi

# Get HA config for timezone etc
echo "[SolarBat-AI] Fetching Home Assistant configuration..."
HA_CONFIG=$(curl -sv -H "Authorization: Bearer ${HA_TOKEN}" "${HA_URL}/api/config" 2>&1 || echo "{}")
echo "[SolarBat-AI] DEBUG: Full response:"
echo "$HA_CONFIG" | head -50

# Try to parse - if it fails, use defaults
LATITUDE=$(echo "$HA_CONFIG" | grep -v '^\*\|^>\|^<\|^{' | tail -1 | jq -r '.latitude // 0' 2>/dev/null || echo "0")
LONGITUDE=$(echo "$HA_CONFIG" | grep -v '^\*\|^>\|^<\|^{' | tail -1 | jq -r '.longitude // 0' 2>/dev/null || echo "0")
ELEVATION=$(echo "$HA_CONFIG" | grep -v '^\*\|^>\|^<\|^{' | tail -1 | jq -r '.elevation // 0' 2>/dev/null || echo "0")
TIMEZONE=$(echo "$HA_CONFIG" | grep -v '^\*\|^>\|^<\|^{' | tail -1 | jq -r '.time_zone // "UTC"' 2>/dev/null || echo "UTC")

echo "[SolarBat-AI] Location: ${LATITUDE}, ${LONGITUDE} (${TIMEZONE})"

# ── Step 4: Generate AppDaemon config ──
echo "[SolarBat-AI] Configuring AppDaemon..."
AD_CONFIG="$APP_DIR/appdaemon.yaml"

sed -e "s|__LATITUDE__|${LATITUDE}|g" \
    -e "s|__LONGITUDE__|${LONGITUDE}|g" \
    -e "s|__ELEVATION__|${ELEVATION}|g" \
    -e "s|__TIMEZONE__|${TIMEZONE}|g" \
    -e "s|__HA_URL__|${HA_URL}|g" \
    -e "s|__HA_TOKEN__|${HA_TOKEN}|g" \
    /app/appdaemon.yaml.template > "$AD_CONFIG"

echo "[SolarBat-AI] DEBUG: Generated appdaemon.yaml:"
cat "$AD_CONFIG"

# ── Step 5: Link apps.yaml from addon config into AppDaemon apps dir ──
mkdir -p "$APP_DIR/apps"
ln -sf "$CONFIG_DIR/apps.yaml" "$APP_DIR/apps/apps.yaml"

# Link data dir for history/cache files
mkdir -p "$DATA_DIR/cache"
ln -sf "$DATA_DIR" "$APP_DIR/apps/solar_optimizer/.data"

# ── Step 6: Launch AppDaemon ──
echo "[SolarBat-AI] Starting AppDaemon on port 5050..."
echo "[SolarBat-AI] Dashboard: http://<your-HA-IP>:5050/api/appdaemon/solar_plan"
echo "============================================="

exec appdaemon -c "$APP_DIR" -p /data/appdaemon.pid