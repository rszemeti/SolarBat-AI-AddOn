# SolarBat-AI

Intelligent solar battery optimizer for Home Assistant. Automatically manages charging and discharging to minimise costs using Octopus Agile pricing, Solcast solar forecasts, and learned consumption patterns.

## Installation

1. Add this repository to Home Assistant: **Settings → Add-ons → Add-on Store → ⋮ → Repositories**
2. Add: `https://github.com/YOUR_USERNAME/solarbat-ai-addon`
3. Find **SolarBat-AI** in the list and click **Install**
4. Click **Start** — the addon will create a template `apps.yaml`
5. Click **Stop**, then edit `apps.yaml` in `/addon_configs/xxx_solarbat-ai/`
6. Update the sensor entity IDs to match your system
7. Remove the `Template: True` line
8. Click **Start** again

## Configuration

Edit `apps.yaml` in your addon config directory. You need to set:

- Battery sensor entity IDs (SOC, capacity)
- Inverter mode select entity and mode names
- Solcast forecast sensor entities
- Octopus Agile pricing entities

See the full configuration guide at the [main repository](https://github.com/YOUR_USERNAME/SolarBat-AI).

## Web Dashboard

Click **Open Web UI** or navigate to `http://<your-HA-IP>:5050/api/appdaemon/solar_plan`

The dashboard has four tabs: Plan, Predictions, Forecast Accuracy, and Settings.

## Log File

The addon log is visible in: **Settings → Add-ons → SolarBat-AI → Log**

## Support

Report issues at: https://github.com/YOUR_USERNAME/SolarBat-AI/issues
