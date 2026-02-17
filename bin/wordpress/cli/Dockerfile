# Builder image with wp-cli and required runtime dependencies for distroless packaging.
FROM dockerhubcolsis/distroless-builder-wp-cli:latest AS builder

# WordPress source version to embed under /var/www/html/wp.
ARG WP_VERSION=latest
# Container timezone (tz database name).
ARG TIME_ZONE="Asia/Tokyo"

# Build as root so filesystem prep can write system locations.
USER root

# Copy WordPress source tree used to populate /var/www/html/wp.
COPY --from=wordpress:php8.3-fpm-alpine /usr/src/wordpress/ /usr/src/wordpress/

# Update builder packages to keep base tooling patched.
RUN set -eux; \
    apk update; \
    apk upgrade --no-cache; \
    apk add --no-cache mariadb-client; \
    rm -rf /var/cache/apk/*;

# Prepare the WordPress layout and fetch a specific core version when requested.
RUN set -eux; \
    mkdir -p \
      /var/www/html/wp \
      /var/www/html/assets/languages \
      /var/www/html/assets/mu-plugins \
      /var/www/html/assets/plugins \
      /var/www/html/assets/themes \
      /var/www/html/assets/uploads && \
    if [ "${WP_VERSION}" = "latest" ]; then \
      cp -a /usr/src/wordpress/. /var/www/html/wp/; \
    else \
      wget -q -O /tmp/wordpress.tar.gz "https://wordpress.org/wordpress-${WP_VERSION}.tar.gz"; \
      tar -xzf /tmp/wordpress.tar.gz -C /tmp; \
      cp -a /tmp/wordpress/. /var/www/html/wp/; \
      rm -rf /tmp/wordpress /tmp/wordpress.tar.gz; \
    fi

# Set runtime PHP defaults used by wp-cli in the container.
RUN set -eux; \
    echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/memory-limit.ini; \
    printf 'date.timezone = "%s"\n' "${TIME_ZONE:-Asia/Tokyo}" > /usr/local/etc/php/conf.d/zz-timezone.ini

# Stage only the runtime filesystem we need for the final distroless image.
RUN set -eux; \
    mkdir -p /opt; \
    BB="$(command -v busybox.static || command -v busybox)"; \
    mkdir -p /opt/usr/bin; \
    cp -a "${BB}" /opt/usr/bin/busybox; \
    chmod 0755 /opt/usr/bin/busybox; \
    ln -sf /usr/bin/busybox /opt/usr/bin/sh; \
    ln -sf /usr/bin/busybox /opt/usr/bin/sleep; \
    ln -sf /usr/bin/busybox /opt/usr/bin/grep; \
    ln -sf /usr/bin/busybox /opt/usr/bin/cat; \
    ln -sf /usr/bin/busybox /opt/usr/bin/less; \
    ln -sf /usr/bin/busybox /opt/usr/bin/rm; \
    ln -sf /usr/bin/busybox /opt/usr/bin/touch; \
    ln -sf /usr/bin/busybox /opt/usr/bin/env; \
    MYSQL_BIN="$(command -v mysql || command -v mariadb || true)"; \
    if [ -n "${MYSQL_BIN}" ]; then \
      cp -aL "${MYSQL_BIN}" /opt/usr/bin/mysql-real; \
      printf '%s\n' \
        '#!/usr/bin/sh' \
        'if [ "${1:-}" = "--no-defaults" ]; then' \
        '  shift' \
        '  exec /usr/bin/mysql-real --no-defaults --skip-ssl "$@"' \
        'fi' \
        'exec /usr/bin/mysql-real --skip-ssl "$@"' \
        > /opt/usr/bin/mysql; \
      chmod 0755 /opt/usr/bin/mysql; \
    fi; \
    cp -a --parents /usr/local /opt; \
    cp -a --parents /var/www/html /opt; \
    cp -a --parents /etc/passwd /opt; \
    cp -a --parents /etc/group /opt; \
    cp -a --parents /etc/ssl /opt; \
    cp -a --parents /usr/lib/mariadb /opt; \
    cp -a --parents /etc/services /opt; \
    cp -a --parents /etc/nsswitch.conf /opt; \
    ( \
      if [ -n "${MYSQL_BIN}" ] && [ -x "${MYSQL_BIN}" ]; then ldd "${MYSQL_BIN}"; fi; \
      if [ -x /usr/local/sbin/php-fpm ]; then ldd /usr/local/sbin/php-fpm; fi; \
      if [ -x /usr/local/bin/php ]; then ldd /usr/local/bin/php; fi; \
      if [ -d /usr/local/lib/php/extensions ]; then \
        find /usr/local/lib/php/extensions -type f -name '*.so' -exec ldd '{}' ';'; \
      fi \
    ) 2>/dev/null \
      | awk '{ if ($3 ~ /^\//) print $3; else if ($1 ~ /^\//) print $1; }' \
      | sort -u \
      | while IFS= read -r so; do \
          case "${so}" in \
            /lib/*) target="/opt/usr/lib/${so#/lib/}" ;; \
            /lib64/*) target="/opt/usr/lib64/${so#/lib64/}" ;; \
            *) target="/opt${so}" ;; \
          esac; \
          mkdir -p "$(dirname "${target}")"; \
          cp -aL "${so}" "${target}"; \
        done; \
    cp /usr/share/zoneinfo/${TIME_ZONE:-ROC} /opt/etc/localtime; \
    find /opt -type f -executable -exec sh -c 'file -i "$1" | grep -q "x-executable; charset=binary"' _ '{}' ';'

# Distroless runtime image.
FROM gcr.io/distroless/static-debian13

# Copy prepared runtime filesystem from the builder stage.
COPY --from=builder /opt /

# Apply project PHP configuration.
COPY ./config/php/php.ini /usr/local/etc/php/php.ini

# Provide the runtime WordPress configuration file.
COPY ./www/wp-config.php /var/www/html/wp/

# Install startup script that performs one-time language updates.
COPY ./bin/wordpress/cli/update-wordpress-languages.sh /usr/local/bin/update-wordpress-languages.sh

# Default working directory for wp-cli commands.
WORKDIR /var/www/html
