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


## Run
Just start `docker run <image>` or explicit `docker run <image> httpd` and the httpd server will be started.
For what reason so ever you might want to run something else you can run `docker run <image> ...` (e.g. `docker run <image> bash`).


## Configuration
The httpd config file can be found at `/etc/httpd/httpd.conf`.
Additionally, there are some environment variables that can be passed to `docker run -e X=Y <image>`
or `docker run --env-file <image>`:
 * HTTPD_CONF="/etc/httpd/httpd.conf"
 * HTTPD_HOME="/var/www"
 * HTTPD_IP=*
 * HTTPD_PORT=8080
 * HTTPD_WEBROOT="/"
