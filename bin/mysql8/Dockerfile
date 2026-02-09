FROM mysql:8

# https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
ARG TIME_ZONE="Asia/Tokyo"

RUN set -eux; \
    cp /usr/share/zoneinfo/${TIME_ZONE:-ROC} /etc/localtime; \
    echo "${TIME_ZONE:-ROC}" > /etc/timezone

RUN echo "[mysqld]" >> /etc/mysql/my.cnf
RUN echo "mysql_native_password=ON" >> /etc/mysql/my.cnf
