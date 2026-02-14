# MySQL 8.4 runtime image for the database service.
FROM mysql:8.4

# Container timezone (tz database name).
ARG TIME_ZONE="Asia/Tokyo"

# Apply timezone settings inside the container.
RUN set -eux; \
    cp /usr/share/zoneinfo/${TIME_ZONE:-ROC} /etc/localtime; \
    echo "${TIME_ZONE:-ROC}" > /etc/timezone

# Ensure mysqld section exists before appending options.
RUN echo "[mysqld]" >> /etc/mysql/my.cnf
# Keep legacy authentication compatibility for local tooling.
RUN echo "mysql_native_password=ON" >> /etc/mysql/my.cnf
