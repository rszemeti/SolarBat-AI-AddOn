ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base-python:3.12-alpine3.19
FROM ${BUILD_FROM}

# Install system deps
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq

# Install Python dependencies
RUN pip3 install --no-cache-dir --break-system-packages \
    appdaemon==4.4.2 \
    requests

# Create directories
RUN mkdir -p /app /config /data

# Copy startup scripts
COPY rootfs/run.sh /run.sh
COPY rootfs/appdaemon.yaml.template /app/appdaemon.yaml.template
COPY rootfs/bootstrap.sh /bootstrap.sh
RUN chmod a+x /run.sh /bootstrap.sh

EXPOSE 5050

CMD ["/run.sh"]
