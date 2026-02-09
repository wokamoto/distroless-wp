FROM mysql:8.4

ARG TIME_ZONE="Asia/Tokyo"

RUN set -eux; \
    cp /usr/share/zoneinfo/${TIME_ZONE:-ROC} /etc/localtime; \
    echo "${TIME_ZONE:-ROC}" > /etc/timezone; \
    echo "[mysqld]" >> /etc/mysql/my.cnf; \
    echo "mysql_native_password=ON" >> /etc/mysql/my.cnf
