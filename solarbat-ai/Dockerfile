ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base-python:3.11-alpine3.18
FROM ${BUILD_FROM}

RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    build-base \
    python3-dev \
    linux-headers

RUN pip3 install --no-cache-dir --break-system-packages \
    appdaemon==4.4.2 \
    requests

RUN apk del --no-cache \
    build-base \
    python3-dev \
    linux-headers

RUN mkdir -p /app /config /data

COPY rootfs/run.sh /run.sh
COPY rootfs/appdaemon.yaml.template /app/appdaemon.yaml.template
COPY rootfs/bootstrap.sh /bootstrap.sh
RUN chmod a+x /run.sh /bootstrap.sh

EXPOSE 5050
CMD ["/run.sh"]