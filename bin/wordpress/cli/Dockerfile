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
    rm -rf /var/cache/apk/*;

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
    fi

# Set runtime PHP defaults used by wp-cli in the container.
RUN set -eux; \
    echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/memory-limit.ini; \
    printf 'date.timezone = "%s"\n' "${TIME_ZONE:-Asia/Tokyo}" > /usr/local/etc/php/conf.d/zz-timezone.ini

# Stage only the runtime filesystem we need for the final distroless image.
RUN set -eux; \
    mkdir -p /opt; \
    cp -a --parents /usr/local /opt; \
    cp -a --parents /var/www/html /opt; \
    cp /usr/share/zoneinfo/${TIME_ZONE:-ROC} /opt/etc/localtime

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
