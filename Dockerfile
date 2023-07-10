FROM alpine:latest
LABEL authors="brunothg"

# Install dependencies
RUN set -x && apk add --no-cache --virtual .build-deps \
      wget \
    && apk add --no-cache \
      busybox-extras \
    bash

# Setup server
COPY src/www/httpd.conf /etc/httpd.conf
COPY src/www/html/* /var/www/

# Clean build artifacts
RUN set -x && rm -Rf /tmp/* \
    && apk del .build-deps

# Install entrypoint
COPY src/entrypoint.sh /root/entrypoint.sh
RUN set -x && chmod 500 /root/entrypoint.sh
ENTRYPOINT ["/root/entrypoint.sh"]
