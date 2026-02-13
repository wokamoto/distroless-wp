FROM wordpress:cli AS builder

ARG WP_VERSION=latest
# https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
ARG TIME_ZONE="Asia/Tokyo"
USER root

COPY --from=wordpress:php8.3-fpm-alpine /usr/src/wordpress/ /usr/src/wordpress/

RUN set -eux; \
    apk add --no-cache tzdata busybox-static wget tar

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
    fi

COPY ./www/wp-config.php /var/www/html/wp/

COPY ./bin/wordpress/cli/update-wordpress-languages.sh /usr/local/bin/update-wordpress-languages.sh

RUN set -eux; \
    echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/memory-limit.ini; \
    printf 'date.timezone = "%s"\n' "${TIME_ZONE:-Asia/Tokyo}" > /usr/local/etc/php/conf.d/zz-timezone.ini

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
    ln -sf /usr/bin/busybox /opt/usr/bin/rm; \
    ln -sf /usr/bin/busybox /opt/usr/bin/touch; \
    ln -sf /usr/bin/busybox /opt/usr/bin/env; \
    cp -a --parents /usr/local /opt; \
    cp -a --parents /var/www/html /opt; \
    cp -a --parents /etc/passwd /opt; \
    cp -a --parents /etc/group /opt; \
    cp -a --parents /etc/ssl /opt; \
    cp -a --parents /etc/services /opt; \
    cp -a --parents /etc/nsswitch.conf /opt; \
    ( \
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
    cp /usr/share/zoneinfo/${TIME_ZONE:-ROC} /opt/etc/localtime

FROM gcr.io/distroless/static-debian13

COPY --from=builder /opt /

COPY ./config/php/php.ini /usr/local/etc/php/php.ini

WORKDIR /var/www/html
