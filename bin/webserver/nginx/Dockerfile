# Builder image that already includes nginx runtime dependencies for distroless packaging.
FROM dockerhubcolsis/distroless-builder-nginx:latest AS builder

# WordPress source version to embed under /var/www/html/wp.
ARG WP_VERSION=latest
# Container timezone (tz database name).
ARG TIME_ZONE="Asia/Tokyo"

# Update builder packages to keep base tooling patched.
RUN set -eux; \
    apk update; \
    apk upgrade --no-cache; \
    rm -rf /var/cache/apk/*;

# Copy WordPress source tree used to populate the web root.
COPY --from=wordpress:php8.3-fpm-alpine /usr/src/wordpress/ /usr/src/wordpress/

# Prepare the WordPress layout and fetch a specific core version when requested.
RUN set -eux; \
    mkdir -p \
      /var/www/html/wp \
      /var/www/html/assets/languages \
      /var/www/html/assets/mu-plugins \
      /var/www/html/assets/plugins \
      /var/www/html/assets/themes \
      /var/www/html/assets/uploads; \
    if [ "${WP_VERSION}" = "latest" ]; then \
      rsync -am --exclude '*.php' --delete /usr/src/wordpress/ /var/www/html/wp/; \
    else \
      wget -q -O /tmp/wordpress.tar.gz "https://wordpress.org/wordpress-${WP_VERSION}.tar.gz"; \
      tar -xzf /tmp/wordpress.tar.gz -C /tmp; \
      rsync -am --exclude '*.php' --delete /tmp/wordpress/ /var/www/html/wp/; \
      rm -rf /tmp/wordpress /tmp/wordpress.tar.gz; \
    fi; \
    printf "%s\n" "<?php // Silence is golden." > /var/www/html/index.php; \
    printf "%s\n" "<?php // Silence is golden." > /var/www/html/wp/wp-admin/index.php; \
    printf "%s\n" "<?php // Silence is golden." > /var/www/html/assets/index.php

# Stage only the runtime filesystem we need for the final distroless image.
RUN set -eux; \
    mkdir -p /opt/var/cache/nginx /opt/etc /opt/var/www/html; \
    cp -a --parents /var/www/html /opt; \
    cp -a --parents /usr/lib/nginx /opt; \
    cp -a --parents /usr/share/nginx /opt; \
    cp -a --parents /var/log/nginx /opt; \
    cp -aL --parents /var/run /opt; \
    cp -a --parents /etc/nginx /opt; \
    cp -a --parents /etc/passwd /opt; \
    cp -a --parents /etc/group /opt; \
    cp -a --parents /usr/sbin/nginx /opt; \
    ldd /usr/sbin/nginx \
      | awk '{ if ($3 ~ /^\//) print $3; else if ($1 ~ /^\//) print $1; }' \
      | sort -u \
      | while IFS= read -r so; do \
          case "$so" in \
            /lib/*) target="/opt/usr/lib/${so#/lib/}" ;; \
            /lib64/*) target="/opt/usr/lib64/${so#/lib64/}" ;; \
            *) target="/opt${so}" ;; \
          esac; \
          mkdir -p "$(dirname "$target")"; \
          cp -aL "$so" "$target"; \
        done; \
    cp /usr/share/zoneinfo/${TIME_ZONE:-ROC} /opt/etc/localtime; \
    find /opt -type f -executable -exec sh -c 'file -i "$1" | grep -q "x-executable; charset=binary"' _ '{}' ';'

# Distroless runtime image.
FROM gcr.io/distroless/static-debian13

# Copy prepared runtime filesystem from the builder stage.
COPY --from=builder /opt /

# Provide nginx and TLS configuration files from this repository.
COPY ./config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./config/nginx/conf.d/ /etc/nginx/conf.d/
COPY ./config/ssl/ /etc/nginx/ssl/

# Expose HTTP/HTTPS ports.
EXPOSE 80 443

# Run nginx in foreground mode.
ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;"]
