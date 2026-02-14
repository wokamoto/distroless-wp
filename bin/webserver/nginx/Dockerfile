FROM dockerhubcolsis/distroless-builder-nginx:latest AS builder

ARG WP_VERSION=latest
# https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
ARG TIME_ZONE="Asia/Tokyo"

RUN set -eux; \
    apk update; \
    apk upgrade --no-cache; \
    rm -rf /var/cache/apk/*;

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
    mkdir -p /opt/var/cache/nginx /opt/etc; \
    cp -a --parents /var/www/html /opt; \
    cp /usr/share/zoneinfo/${TIME_ZONE:-ROC} /opt/etc/localtime

FROM gcr.io/distroless/static-debian13

COPY --from=builder /opt /

COPY ./config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./config/nginx/conf.d/ /etc/nginx/conf.d/
COPY ./config/ssl/ /etc/nginx/ssl/

EXPOSE 80 443

ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;"]
