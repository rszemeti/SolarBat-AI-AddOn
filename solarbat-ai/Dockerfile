ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base-python:3.12-bullseye
ARG BUILD_VERSION
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    git \
    jq \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Set workdir
WORKDIR /app

# Copy app files
COPY rootfs/ /app/

# Install Python dependencies
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

# Make scripts executable
RUN chmod +x /app/run.sh /app/bootstrap.sh

EXPOSE 5050

CMD ["/app/run.sh"]

# Metadata
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="rszemeti (https://github.com/rszemeti)" \
    org.opencontainers.image.version=${BUILD_VERSION} \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.source="https://github.com/rszemeti/SolarBat-AI"
