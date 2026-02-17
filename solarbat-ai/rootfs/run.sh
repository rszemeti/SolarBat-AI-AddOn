#!/usr/bin/env bash
# run.sh - SolarBat-AI addon entrypoint
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
# Try multiple ways to get the supervisor token
HA_TOKEN="${SUPERVISOR_TOKEN:-}"

# Try s6 environment file if env var is empty
if [ -z "$HA_TOKEN" ] && [ -f /run/s6/container_environment/SUPERVISOR_TOKEN ]; then
    HA_TOKEN=$(cat /run/s6/container_environment/SUPERVISOR_TOKEN)
    echo "[SolarBat-AI] Got token from s6 container environment"
fi

# Try s6-overlay v3 path
if [ -z "$HA_TOKEN" ] && [ -f /var/run/s6/container_environment/SUPERVISOR_TOKEN ]; then
    HA_TOKEN=$(cat /var/run/s6/container_environment/SUPERVISOR_TOKEN)
    echo "[SolarBat-AI] Got token from s6-overlay v3 environment"
fi

# Last resort: check if __SUPERVISOR_TOKEN is set (some versions use this)
if [ -z "$HA_TOKEN" ] && [ -n "${__SUPERVISOR_TOKEN:-}" ]; then
    HA_TOKEN="${__SUPERVISOR_TOKEN}"
    echo "[SolarBat-AI] Got token from __SUPERVISOR_TOKEN"
fi

HA_URL="http://supervisor/core"

echo "[SolarBat-AI] DEBUG: SUPERVISOR_TOKEN length=${#HA_TOKEN}"
echo "[SolarBat-AI] DEBUG: Env vars containing TOKEN:"
env | grep -i token | sed 's/=.*/=<redacted>/' || echo "  (none found)"
echo "[SolarBat-AI] DEBUG: Checking s6 env files:"
ls -la /run/s6/container_environment/ 2>/dev/null | head -20 || echo "  /run/s6/container_environment/ not found"
ls -la /var/run/s6/container_environment/ 2>/dev/null | head -20 || echo "  /var/run/s6/container_environment/ not found"

if [ -z "$HA_TOKEN" ]; then
    echo "[SolarBat-AI] ERROR: No SUPERVISOR_TOKEN found anywhere!"
    echo "[SolarBat-AI] This addon requires hassio_api: true and homeassistant_api: true in config.yaml"
fi

# Get HA config for timezone etc
echo "[SolarBat-AI] Fetching Home Assistant configuration..."
HA_CONFIG=$(curl -s -H "Authorization: Bearer ${HA_TOKEN}" "${HA_URL}/api/config" 2>/dev/null || echo "{}")

# Check if we got valid JSON
if echo "$HA_CONFIG" | jq . >/dev/null 2>&1; then
    LATITUDE=$(echo "$HA_CONFIG" | jq -r '.latitude // 0')
    LONGITUDE=$(echo "$HA_CONFIG" | jq -r '.longitude // 0')
    ELEVATION=$(echo "$HA_CONFIG" | jq -r '.elevation // 0')
    TIMEZONE=$(echo "$HA_CONFIG" | jq -r '.time_zone // "UTC"')
    echo "[SolarBat-AI] Location: ${LATITUDE}, ${LONGITUDE} (${TIMEZONE})"
else
    echo "[SolarBat-AI] Warning: Could not fetch HA config, using defaults"
    echo "[SolarBat-AI] Response was: ${HA_CONFIG:0:200}"
    LATITUDE="0"
    LONGITUDE="0"
    ELEVATION="0"
    TIMEZONE="UTC"
fi

# ── Step 4: Generate AppDaemon config ──
echo "[SolarBat-AI] Configuring AppDaemon..."
AD_CONFIG="$APP_DIR/appdaemon.yaml"

# Create secrets file so AppDaemon doesn't crash
touch /config/secrets.yaml 2>/dev/null || true

# Write config directly instead of using template (more reliable)
cat > "$AD_CONFIG" << EOF
appdaemon:
  latitude: ${LATITUDE}
  longitude: ${LONGITUDE}
  elevation: ${ELEVATION}
  time_zone: ${TIMEZONE}
  app_dir: /app/apps
  plugins:
    HASS:
      type: hass
      ha_url: "${HA_URL}"
      token: "${HA_TOKEN}"
http:
  url: http://0.0.0.0:5050
admin:
api:
hadashboard:
EOF

echo "[SolarBat-AI] DEBUG: Generated appdaemon.yaml (token redacted):"
sed 's/token: ".*"/token: "<redacted>"/' "$AD_CONFIG"

# ── Step 5: Link apps.yaml from addon config into AppDaemon apps dir ──
mkdir -p "$APP_DIR/apps"
ln -sf "$CONFIG_DIR/apps.yaml" "$APP_DIR/apps/apps.yaml"

# Link data dir for history/cache files
mkdir -p "$DATA_DIR/cache"
if [ -d "$APP_DIR/apps/solar_optimizer" ]; then
    ln -sf "$DATA_DIR" "$APP_DIR/apps/solar_optimizer/.data"
fi

# ── Step 6: Launch AppDaemon ──
echo "[SolarBat-AI] Starting AppDaemon on port 5050..."
echo "============================================="

exec appdaemon -c "$APP_DIR" -p /data/appdaemon.pid