ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base-python:3.12-alpine3.19
FROM ${BUILD_FROM}

# Install system dependencies
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    libffi

# Install all Python dependencies in one layer
RUN pip3 install --no-cache-dir --break-system-packages \
    appdaemon==4.4.2 \
    requests \
    aiohttp~=3.8.4 \
    aiohttp-jinja2~=1.5.1 \
    astral~=3.2 \
    bcrypt~=4.0.1 \
    deepdiff==6.3.0 \
    feedparser~=6.0.10 \
    iso8601~=1.1.0 \
    paho-mqtt~=1.6.1 \
    pid~=3.0.4 \
    python-dateutil~=2.8.2 \
    "python-socketio<5.9,>=5.5" \
    "pytz<2023.4.0,>=2022.7.1" \
    pyyaml~=6.0 \
    sockjs~=0.11.0 \
    websocket-client~=1.5.1 \
    tomli~=2.0.1 \
    tomli-w~=1.0.0

# Create directories
RUN mkdir -p /app /config /data

# Copy startup scripts
COPY rootfs/run.sh /run.sh
COPY rootfs/appdaemon.yaml.template /app/appdaemon.yaml.template
COPY rootfs/bootstrap.sh /bootstrap.sh
RUN chmod a+x /run.sh /bootstrap.sh

EXPOSE 5050

CMD ["/run.sh"]
