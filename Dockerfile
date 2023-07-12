# Copyright 2023 brunothg
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0

ARG ALPINE_VERSION="latest"

FROM alpine:$ALPINE_VERSION
LABEL authors="brunothg"

ENV ALPINE_VERSION="$ALPINE_VERSION"

ARG HTTPD_CONF="/etc/httpd/httpd.conf"
ENV HTTPD_CONF="${HTTPD_CONF}"

ARG HTTPD_HOME="/var/www"
ENV HTTPD_HOME="$HTTPD_HOME"

ARG HOMER_VERSION="latest"
ENV HOMER_VERSION="$HOMER_VERSION"


# Setup environment
WORKDIR "${HTTPD_HOME}"
COPY src/httpd/execute.sh /usr/local/bin/execute
COPY src/httpd/php.override.ini /etc/php82/conf.d/php.override.ini
RUN set -x  \
    && mkdir -p "$HTTPD_HOME" \
    && mkdir -p "$(dirname "$HTTPD_CONF")" \
    && apk add --no-cache --virtual .build-deps \
      wget \
      unzip \
    && apk add --no-cache \
      busybox-extras \
      bash \
      php82-cgi \
    && ln -s "/usr/bin/php-cgi82" "/usr/bin/php-cgi" \
    && chmod 555 /usr/local/bin/execute && dos2unix /usr/local/bin/execute \
    && chmod 444 /etc/php82/conf.d/php.override.ini && dos2unix /etc/php82/conf.d/php.override.ini


# Setup server
COPY src/httpd/httpd.conf "${HTTPD_CONF}"
COPY src/www/ "/tmp/www/"
COPY LICENSE "/tmp/www/LICENSE"
RUN set -x \
    && dos2unix "${HTTPD_CONF}" \
    && wget "https://github.com/bastienwirtz/homer/releases$(if [ "$HOMER_VERSION" == "latest" ]; then echo "/latest"; fi)/download$(if [ "$HOMER_VERSION" != "latest" ]; then echo "/$HOMER_VERSION"; fi)/homer.zip" -O "/tmp/homer.zip" \
    && unzip -d "${HTTPD_HOME}" "/tmp/homer.zip" \
    && mv "${HTTPD_HOME}/assets/config.yml.dist" "${HTTPD_HOME}/assets/config.yml" \
    && find "${HTTPD_HOME}/assets/" -mindepth 1 -maxdepth 1 ! -name 'manifest.json' ! -name 'icons' -exec rm -rf {} ';' \
    && rm -f "${HTTPD_HOME}/logo.png" \
    && cp -a "/tmp/www/." "${HTTPD_HOME}" \
    && find . -type f '(' -iname '*.sh' -o -iname '*.php' -o -iname '*.cgi' ')' -exec chmod 550 {} ';' -exec dos2unix {} ';' \
    && chmod 444 "${HTTPD_CONF}" && dos2unix "${HTTPD_CONF}"


# Clean build artifacts
RUN set -x && \
    rm -rf /tmp/* \
    && apk del .build-deps


# Install entrypoint
COPY src/entrypoint.sh /root/entrypoint.sh
RUN set -x \
    && chmod 500 /root/entrypoint.sh && dos2unix /root/entrypoint.sh
ENTRYPOINT ["/root/entrypoint.sh"]
