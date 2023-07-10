FROM alpine:latest
LABEL authors="brunothg"

ARG HTTPD_CONF="/etc/httpd/httpd.conf"
ENV HTTPD_CONF="${HTTPD_CONF}"

ARG HTTPD_HOME="/var/www"
ENV HTTPD_HOME="$HTTPD_HOME"

# Install dependencies
RUN set -x && apk add --no-cache --virtual .build-deps \
      wget \
    && apk add --no-cache \
      busybox-extras \
      bash

# Setup server
COPY src/httpd/httpd.conf "${HTTPD_CONF}"
COPY src/www/* "$HTTPD_HOME/"

# Clean build artifacts
RUN set -x && rm -Rf /tmp/* \
    && apk del .build-deps

# Install entrypoint
COPY src/entrypoint.sh /root/entrypoint.sh
RUN set -x && chmod 500 /root/entrypoint.sh
ENTRYPOINT ["/root/entrypoint.sh"]
