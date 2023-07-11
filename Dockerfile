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
      bash \
      php82-cgi \
    && ln -s "/usr/bin/php-cgi82" "/usr/bin/php-cgi"
COPY src/httpd/php.override.ini /etc/php82/conf.d/php.override.ini

# Setup server
COPY src/httpd/httpd.conf "${HTTPD_CONF}"
COPY src/www/ "/tmp/www/"
RUN set -x \
    && dos2unix "${HTTPD_CONF}" \
    && wget "https://github.com/bastienwirtz/homer/releases$(if [ "$HOMER_VERSION" == "latest" ]; then echo "/latest"; fi)/download$(if [ "$HOMER_VERSION" != "latest" ]; then echo "/$HOMER_VERSION"; fi)/homer.zip" -O "/tmp/homer.zip" \
    && unzip -d "${HTTPD_HOME}" "/tmp/homer.zip" \
    && mv "${HTTPD_HOME}/assets/config.yml.dist" "${HTTPD_HOME}/assets/config.yml" \
    && find assets/ -type f -maxdepth 1 ! -name '*.json' ! -name '*.yml' \
    && cp -a "/tmp/www/." "${HTTPD_HOME}" \
    && chmod 550 "${HTTPD_HOME}"/**/*.cgi \
    && chmod 550 "${HTTPD_HOME}"/**/*.php


# Clean build artifacts
RUN set -x && rm -Rf /tmp/* \
    && apk del .build-deps

# Install entrypoint
COPY src/entrypoint.sh /root/entrypoint.sh
RUN set -x \
    && chmod 500 /root/entrypoint.sh \
    && dos2unix /root/entrypoint.sh
ENTRYPOINT ["/root/entrypoint.sh"]
