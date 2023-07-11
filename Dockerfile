FROM alpine:latest
LABEL authors="brunothg"

ARG HTTPD_CONF="/etc/httpd/httpd.conf"
ENV HTTPD_CONF="${HTTPD_CONF}"

ARG HTTPD_HOME="/var/www"
ENV HTTPD_HOME="$HTTPD_HOME"

ARG HOMER_VERSION="latest"
ENV HOMER_VERSION="$HOMER_VERSION"

# Setup environment
WORKDIR "${HTTPD_HOME}"
RUN set -x  \
    && mkdir -p "$HTTPD_HOME" \
    && mkdir -p "$(dirname "$HTTPD_CONF")" \
    && apk add --no-cache --virtual .build-deps \
      wget \
      unzip \
    && apk add --no-cache \
      busybox-extras \
      bash

# Setup server
COPY src/httpd/httpd.conf "${HTTPD_CONF}"
RUN set -x \
    && wget "https://github.com/bastienwirtz/homer/releases$(if [ "$HOMER_VERSION" == "latest" ]; then echo "/latest"; fi)/download$(if [ "$HOMER_VERSION" != "latest" ]; then echo "/$HOMER_VERSION"; fi)/homer.zip" -O "/tmp/homer.zip" \
    && unzip -d "${HTTPD_HOME}" "/tmp/homer.zip" \
    && mv "${HTTPD_HOME}/assets/config.yml.dist" "${HTTPD_HOME}/assets/config.yml" \
    && find assets/ -type f -maxdepth 1 ! -name '*.json' ! -name '*.yml'
COPY src/www/ "$HTTPD_HOME/"

# Clean build artifacts
RUN set -x && rm -Rf /tmp/* \
    && apk del .build-deps

# Install entrypoint
COPY src/entrypoint.sh /root/entrypoint.sh
RUN set -x \
    && chmod 500 /root/entrypoint.sh \
    && dos2unix /root/entrypoint.sh
ENTRYPOINT ["/root/entrypoint.sh"]
