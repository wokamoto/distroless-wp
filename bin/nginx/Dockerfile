FROM nginx:1.29 AS builder

# https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
ARG TIME_ZONE="Asia/Tokyo"

RUN set -eux; \
    mkdir -p /opt/var/cache/nginx /opt/etc; \
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
    cp /usr/share/zoneinfo/${TIME_ZONE:-ROC} /opt/etc/localtime

FROM gcr.io/distroless/base-debian13

COPY --from=builder /opt /

COPY ./config/nginx/nginx.conf /etc/nginx/nginx.conf

COPY ./config/nginx/conf.d/ /etc/nginx/conf.d/

COPY ./config/ssl/ /etc/nginx/ssl/

EXPOSE 80 443

ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;"]
