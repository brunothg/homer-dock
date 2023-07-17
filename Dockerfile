# Copyright 2023 brunothg
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0

ARG ALPINE_VERSION="latest"
FROM alpine:$ALPINE_VERSION
ENV ALPINE_VERSION="$ALPINE_VERSION"

LABEL org.opencontainers.image.authors="brunothg"
LABEL org.opencontainers.image.source="https://github.com/brunothg/homer-dock"
LABEL org.opencontainers.image.description="Docker image for Homer dashboard with web configuration UI"
LABEL org.opencontainers.image.licenses="Apache-2.0"


# Setup environment
ARG HTTPD_HOME="/var/www"
ENV HTTPD_HOME="$HTTPD_HOME"

ARG HOMER_VERSION="latest"
ENV HOMER_VERSION="$HOMER_VERSION"

ENV VERSIONS_HOME="/etc/full-versions"

COPY src/httpd/execute.sh /usr/local/bin/execute
COPY src/httpd/php.override.ini /etc/php82/conf.d/php.override.ini
RUN set -x  \
    && apk add --no-cache --virtual .build-deps \
          wget \
          jq \
          unzip \
    && mkdir -p "$VERSIONS_HOME" \
    && wget -q --output-document - https://api.github.com/repos/bastienwirtz/homer/releases | jq -r ". | sort_by(.name) | reverse | [.[] | select(.name | test(\"^v$HOMER_VERSION([.].*)?$\"))][0] | .name" | cut -c 2- > "$VERSIONS_HOME/HOMER_FULL_VERSION" \
    && grep '^VERSION' /etc/os-release | cut -d = -f2 > "$VERSIONS_HOME/ALPINE_FULL_VERSION" \
    && mkdir -p "$HTTPD_HOME" \
    && mkdir -p "$(dirname "$HTTPD_CONF")" \
    && apk add --no-cache \
      busybox-extras \
      bash \
      php82-cgi \
    && ln -s "/usr/bin/php-cgi82" "/usr/bin/php-cgi" \
    && chmod 555 /usr/local/bin/execute && dos2unix /usr/local/bin/execute \
    && chmod 444 /etc/php82/conf.d/php.override.ini && dos2unix /etc/php82/conf.d/php.override.ini \
    && wget "https://github.com/bastienwirtz/homer/releases/download/v$(cat "$VERSIONS_HOME/HOMER_FULL_VERSION")/homer.zip" -O "/tmp/homer.zip" \
    && unzip -d "${HTTPD_HOME}" "/tmp/homer.zip"


# Setup server
ARG HTTPD_CONF="/etc/httpd/httpd.conf"
ENV HTTPD_CONF="${HTTPD_CONF}"

COPY src/httpd/httpd.conf "${HTTPD_CONF}"
COPY src/www/ "/tmp/www/"
COPY LICENSE "/tmp/www/LICENSE"
RUN set -x \
    && chmod 444 "${HTTPD_CONF}" && dos2unix "${HTTPD_CONF}" \
    && find "${HTTPD_HOME}/assets/" -mindepth 1 -maxdepth 1 ! -name 'manifest.json' ! -name 'icons' -exec rm -rf {} ';' \
    && rm -f "${HTTPD_HOME}/logo.png" \
    && cp -a "/tmp/www/." "${HTTPD_HOME}" \
    && find "${HTTPD_HOME}" -type f '(' -iname '*.sh' -o -iname '*.exec' -o -iname '*.cgi' ')' -exec chmod 550 {} ';' -exec dos2unix {} ';'


# Clean build artifacts
RUN set -x && \
    rm -rf /tmp/* \
    && apk del .build-deps


# Install entrypoint
COPY src/entrypoint.sh /root/entrypoint.sh
RUN set -x \
    && chmod 500 /root/entrypoint.sh && dos2unix /root/entrypoint.sh
WORKDIR "${HTTPD_HOME}"
ENTRYPOINT ["/root/entrypoint.sh"]
