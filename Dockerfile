# Copyright 2023 brunothg
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0

ARG ALPINE_VERSION="latest"
FROM alpine:$ALPINE_VERSION

LABEL org.opencontainers.image.authors="brunothg"
LABEL org.opencontainers.image.source="https://github.com/brunothg/homer-dock"
LABEL org.opencontainers.image.description="Docker image for Homer dashboard with web configuration UI"
LABEL org.opencontainers.image.licenses="Apache-2.0"

# Setup environment
ARG HTTPD_HOME="/var/www"
ARG HTTPD_CONF="/etc/httpd/httpd.conf"
ARG HOMER_VERSION="latest"

ENV ALPINE_VERSION="$ALPINE_VERSION" \
    HTTPD_HOME="$HTTPD_HOME" \
    HTTPD_CONF="${HTTPD_CONF}" \
    HOMER_VERSION="$HOMER_VERSION"

# Install deps
RUN set -x  \
    && echo "Install dependencies" \
    && echo "Add build dependencies" && apk add --no-cache --virtual .build-deps \
          wget \
          unzip \
    && echo "Add runtime depdendencies" && apk add --no-cache \
      busybox-extras \
      bash \
      php82-cgi \
    && echo "Setup CGI bin link" && ( [ -e "/usr/bin/php-cgi" ] || ln -s "/usr/bin/php-cgi82" "/usr/bin/php-cgi" ) \
    && echo "Add homer" && mkdir -p "$HTTPD_HOME" && wget "https://github.com/bastienwirtz/homer/releases/download/$HOMER_VERSION/homer.zip" -O "/tmp/homer.zip" && unzip -d "${HTTPD_HOME}" "/tmp/homer.zip" \
    && echo "Remove temporary artifacts" && rm -rf /tmp/* && apk del .build-deps


# Setup server
COPY src/ "/tmp/src/"
RUN set -x \
    && echo "Setup server" \
    && echo "Add execute bin" && cp -a "/tmp/src/httpd/execute.sh" "/usr/local/bin/execute" && chmod 555 "/usr/local/bin/execute" && dos2unix "/usr/local/bin/execute" \
    && echo "Add php config" && cp -a "/tmp/src/httpd/php.override.ini" "/etc/php82/conf.d/php.override.ini" && chmod 444 "/etc/php82/conf.d/php.override.ini" && dos2unix "/etc/php82/conf.d/php.override.ini" \
    && echo "Add httpd config" && mkdir -p "$(dirname "$HTTPD_CONF")" && cp -a "/tmp/src/httpd/httpd.conf" "${HTTPD_CONF}" && chmod 444 "${HTTPD_CONF}" && dos2unix "${HTTPD_CONF}" \
    && echo "Remove unused homer artifacts" && find "${HTTPD_HOME}/assets/" -mindepth 1 -maxdepth 1 ! -name 'manifest.json' ! -name 'icons' -exec rm -rf {} ';' \
    && echo "Remove default homer logo" && rm -f "${HTTPD_HOME}/logo.png" \
    && echo "Add homer config ui" && cp -a "/tmp/src/www/." "${HTTPD_HOME}" && find "${HTTPD_HOME}" -type f '(' -iname '*.sh' -o -iname '*.exec' -o -iname '*.cgi' ')' -exec chmod 550 {} ';' -exec dos2unix {} ';' \
    && echo "Install entrypoint" && cp -a "/tmp/src/entrypoint.sh" "/root/entrypoint.sh" && chmod 500 "/root/entrypoint.sh" && dos2unix "/root/entrypoint.sh" \
    && echo "Remove temporary artifacts" && rm -rf /tmp/*

WORKDIR "${HTTPD_HOME}"
ENTRYPOINT ["/root/entrypoint.sh"]
