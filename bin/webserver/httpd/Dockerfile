FROM httpd:2.4-alpine AS builder

ARG WP_VERSION=latest
# https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
ARG TIME_ZONE="Asia/Tokyo"

RUN set -eux; \
    apk add --no-cache tzdata wget tar

COPY --from=wordpress:php8.3-fpm-alpine /usr/src/wordpress/ /usr/src/wordpress/

RUN set -eux; \
    mkdir -p \
      /var/www/html/wp \
      /var/www/html/content/languages \
      /var/www/html/content/mu-plugins \
      /var/www/html/content/plugins \
      /var/www/html/content/themes \
      /var/www/html/content/uploads; \
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
    printf "%s\n" "<?php // Silence is golden." > /var/www/html/content/index.php

  RUN set -eux; \
    mkdir -p /opt/etc; \
    cp -a --parents /var/www/html /opt; \
    cp -a --parents /usr/local/apache2 /opt; \
    cp -a --parents /etc/passwd /opt; \
    cp -a --parents /etc/group /opt; \
    cp -aL --parents /var/run /opt; \
    ( \
      ldd /usr/local/apache2/bin/httpd; \
      find /usr/local/apache2/modules -type f -name '*.so' -exec ldd '{}' ';' \
    ) 2>/dev/null \
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
    cp /usr/share/zoneinfo/${TIME_ZONE:-ROC} /opt/etc/localtime

FROM gcr.io/distroless/base-debian13

COPY --from=builder /opt /

COPY ./config/httpd/httpd.conf /usr/local/apache2/conf/httpd.conf
COPY ./config/httpd/conf.d/ /usr/local/apache2/conf/conf.d/

EXPOSE 80

ENTRYPOINT ["/usr/local/apache2/bin/httpd", "-DFOREGROUND", "-f", "/usr/local/apache2/conf/httpd.conf"]
