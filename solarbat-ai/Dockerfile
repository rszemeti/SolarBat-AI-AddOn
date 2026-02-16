ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install system deps
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq

# Install Python dependencies
# Option 1: AppDaemon bundled inside container
# Option 2 (future): replace appdaemon with lightweight HA websocket client
RUN pip3 install --no-cache-dir --break-system-packages \
    appdaemon==4.4.2 \
    requests

# Create directories
RUN mkdir -p /app /config /data

# Copy startup scripts
COPY rootfs/run.sh /run.sh
COPY rootfs/appdaemon.yaml /app/appdaemon.yaml.template
COPY rootfs/bootstrap.sh /bootstrap.sh
RUN chmod a+x /run.sh /bootstrap.sh

EXPOSE 5050

CMD ["/run.sh"]
