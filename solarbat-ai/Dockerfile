ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install system deps + build tools for uvloop compilation
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    build-base \
    python3-dev \
    linux-headers

# Install Python dependencies
RUN pip3 install --no-cache-dir --break-system-packages \
    appdaemon==4.4.2 \
    requests

# Remove build tools to keep image small
RUN apk del --no-cache \
    build-base \
    python3-dev \
    linux-headers

# Create directories
RUN mkdir -p /app /config /data

# Copy startup scripts
COPY rootfs/run.sh /run.sh
COPY rootfs/appdaemon.yaml.template /app/appdaemon.yaml.template
COPY rootfs/bootstrap.sh /bootstrap.sh
RUN chmod a+x /run.sh /bootstrap.sh

EXPOSE 5050

CMD ["/run.sh"]