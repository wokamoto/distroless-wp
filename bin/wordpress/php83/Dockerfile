# Builder image with PHP 8.3 FPM runtime dependencies for distroless packaging.
FROM dockerhubcolsis/distroless-builder-php8.3:latest AS builder

# WordPress source version to embed under /var/www/html/wp.
ARG WP_VERSION=latest
# Container timezone (tz database name).
ARG TIME_ZONE="Asia/Tokyo"

# Update builder packages to keep base tooling patched.
RUN set -eux; \
    apk update; \
    apk upgrade --no-cache; \
    rm -rf /var/cache/apk/*;

# Copy WordPress source tree used to populate /var/www/html/wp.
COPY --from=wordpress:php8.3-fpm-alpine /usr/src/wordpress/ /usr/src/wordpress/

# Prepare the WordPress layout and fetch a specific core version when requested.
RUN set -eux; \
    mkdir -p \
      /var/www/html/wp \
      /var/www/html/content/languages \
      /var/www/html/content/mu-plugins \
      /var/www/html/content/plugins \
      /var/www/html/content/themes \
      /var/www/html/content/uploads && \
    if [ "${WP_VERSION}" = "latest" ]; then \
      cp -a /usr/src/wordpress/. /var/www/html/wp/; \
    else \
      wget -q -O /tmp/wordpress.tar.gz "https://wordpress.org/wordpress-${WP_VERSION}.tar.gz"; \
      tar -xzf /tmp/wordpress.tar.gz -C /tmp; \
      cp -a /tmp/wordpress/. /var/www/html/wp/; \
      rm -rf /tmp/wordpress /tmp/wordpress.tar.gz; \
    fi; \
    printf "%s\n" "<?php" "define( 'WP_USE_THEMES', true );" "require __DIR__ . '/wp/wp-blog-header.php';" > /var/www/html/index.php; \
    printf "%s\n" "<?php // Silence is golden." > /var/www/html/content/index.php; \
    chown -R www-data:www-data /var/www/html

# Provide runtime wp-config.php from this repository.
COPY ./www/wp-config.php /var/www/html/wp/

# Set runtime PHP defaults for memory limit and timezone.
RUN set -eux; \
    echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/memory-limit.ini; \
    printf 'date.timezone = "%s"\n' "${TIME_ZONE:-Asia/Tokyo}" > /usr/local/etc/php/conf.d/zz-timezone.ini

# Stage only the runtime filesystem we need for the final distroless image.
RUN set -eux; \
    mkdir -p /opt; \
    cp -a --parents /usr/local /opt; \
    cp -a --parents /var/www/html /opt; \
    cp -a --parents /etc/passwd /opt; \
    cp -a --parents /etc/group /opt; \
    cp -a --parents /etc/ssl /opt; \
    cp -a --parents /etc/services /opt; \
    cp -a --parents /etc/nsswitch.conf /opt; \
    ( \
      ldd /usr/local/sbin/php-fpm; \
      ldd /usr/local/bin/php; \
      find /usr/local/lib/php/extensions -type f -name '*.so' -exec ldd '{}' ';' \
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

# Apply project PHP-fpm configuration.
COPY ./config/php/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

# Default working directory for the php-fpm runtime.
WORKDIR /var/www/html

# Expose php-fpm listener port.
EXPOSE 9000

# Run php-fpm in foreground mode.
ENTRYPOINT ["/usr/local/sbin/php-fpm", "-F"]
