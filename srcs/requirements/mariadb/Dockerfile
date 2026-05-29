FROM alpine:3.23

RUN apk add --no-cache mariadb mariadb-client && \
    mkdir -p /run/mysqld /var/log/mysql && \
    chown -R mysql:mysql /run/mysqld /var/log/mysql && \
    chmod 755 /run/mysqld && \
    sed -i '/skip.networking/d' /etc/my.cnf.d/mariadb-server.cnf

COPY ./conf/50-server.cnf /etc/my.cnf.d/

COPY ./tools/script.sh /

RUN chmod +x /script.sh

EXPOSE 3306

CMD ["/script.sh"]
