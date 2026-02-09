FROM wordpress:php8.5-fpm-alpine AS builder

ARG WP_VERSION=latest
# https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
ARG TIME_ZONE="Asia/Tokyo"

RUN set -eux; \
    apk add --no-cache tzdata

RUN set -eux; \
    mkdir -p \
      /var/www/html/wp \
      /var/www/html/content/languages \
      /var/www/html/content/mu-plugins \
      /var/www/html/content/plugins \
      /var/www/html/content/themes \
      /var/www/html/content/uploads

COPY ./www/wp-config.php /var/www/html/wp/

RUN set -eux; \
    echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/memory-limit.ini; \
    printf 'date.timezone = "%s"\n' "${TIME_ZONE:-Asia/Tokyo}" > /usr/local/etc/php/conf.d/zz-timezone.ini

RUN set -eux; \
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
    cp /usr/share/zoneinfo/${TIME_ZONE:-ROC} /opt/etc/localtime

FROM gcr.io/distroless/base-debian13

COPY --from=builder /opt /

COPY ./config/php/php.ini /usr/local/etc/php/php.ini
COPY ./config/php/php-fpm-log.conf /usr/local/etc/php-fpm.d/zz-log.conf

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/sbin/php-fpm", "-F"]
