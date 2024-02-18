[//]: # (Copyright 2023 brunothg)
[//]: # (   Licensed under the Apache License, Version 2.0 &#40;the "License"&#41;;)
[//]: # (   you may not use this file except in compliance with the License.)
[//]: # (   You may obtain a copy of the License at)
[//]: # (       http://www.apache.org/licenses/LICENSE-2.0)

# Homer-Dock
Docker container for Homer dashboard: [bastienwirtz/homer](https://github.com/bastienwirtz/homer)

This image is not meant to be exposed to the web itself.
It is designed to be lightweight (backed by BusyBox httpd) and capable of being served by a reverse proxy.

![License](https://img.shields.io/github/license/brunothg/homer-dock)
![Release](https://img.shields.io/github/v/release/brunothg/homer-dock)


![Dashboard](https://raw.github.com/brunothg/homer-dock/main/docs/screenshot-dashboard.png)

![Configuration](https://raw.github.com/brunothg/homer-dock/main/docs/screenshot-config.png)

![Manifest configuration](https://raw.github.com/brunothg/homer-dock/main/docs/screenshot-config-manifest.png)

![Message configuration](https://raw.github.com/brunothg/homer-dock/main/docs/screenshot-config-message.png)

![Dashboard configuration](https://raw.github.com/brunothg/homer-dock/main/docs/screenshot-config-dashboard.png)


## Run
Just start `docker run <image>` or explicit `docker run <image> httpd` and the httpd server will be started.
For what reason so ever you might want to run something else you can run `docker run <image> ...` (e.g. `docker run <image> bash`).


## Configuration
The httpd config file can be found at `/etc/httpd/httpd.conf`.
Homer can be configured per web ui or by editing `/var/www/assets/config.yml` ([DOCS](https://github.com/bastienwirtz/homer/blob/main/docs/configuration.md)).
Additionally, there are some environment variables that can be passed to `docker run -e X=Y <image>`
or `docker run --env-file <image>`:
 * HTTPD_IP=* (Set ip adress httpd should bind to)
 * HTTPD_PORT=8080 (Set port httpd should bind to)
 * HTTPD_WEBROOT="/" (Set webroot from where httpd should serve the website)
 * HTTPD_USERID=82 (Set id for www-data user used by httpd)
 * HTTPD_GROUPID=$HTTPD_USERID (Set id for www-data group used by httpd)
 * HOMER_WEB_CONFIG=1 (En-/Disable web config user interface)

## Nginx config
Using Nginx as reverse proxy, you can use the following extract as a base configuration:

    set $HOMER_MASTER http://localhost:8080
    location ~ ^(?<prefix>/homer)$ {
        return 301 $schema://$host:$server_port$prefix/;
    }
    location ~ ^(?<prefix>/homer)(?<local_path>/.*) {
        proxy_set_header Host $host;
        
        rewrite ^ $local_path break;
        proxy_pass $HOMER_MASTER;
        proxy_redirect $HOMER_MASTER $prefix;

        location ~ ^(?<prefix>/homer)(?<local_path>/config/.*) {
            auth_basic "Homer Configuration";
            auth_basic_user_file /etc/apache2/.htpasswd;

            proxy_set_header Host $host;
        
            rewrite ^ $local_path break;
            proxy_pass $HOMER_MASTER;
            proxy_redirect $HOMER_MASTER $prefix;
        }
    }

## Docker compose
For docker/podman you may want to use the following as a starting point:

    ---
    version: '3'
    services:
        homer:
            image: ghcr.io/brunothg/homer-dock:latest
            command: httpd
            ports:
                - "8080:8080"
            volumes:
                - assets:/var/www/assets
    volumes:
        assets:
            driver: local
            driver_opts:
                type: none
                o: bind
                device: "/<path to persistent storage>"
