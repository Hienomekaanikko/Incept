FROM alpine:3.21

RUN apk add --no-cache \
    php83 php83-fpm php83-mysqli php83-pdo_mysql \
    php83-json php83-mbstring php83-xml php83-dom \
    php83-simplexml php83-tokenizer php83-curl \
    php83-openssl php83-zip php83-fileinfo php83-iconv \
    php83-gd php83-intl php83-phar php83-session \
    mariadb-client curl && \
    ln -s /usr/bin/php83 /usr/local/bin/php && \
    curl -o /usr/local/bin/wp \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp && \
    echo "memory_limit = -1" >> /etc/php83/php.ini

WORKDIR /var/www/html

COPY ./conf/www.conf /etc/php83/php-fpm.d/www.conf

COPY ./tools/script.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/script.sh

EXPOSE 9000

CMD ["/usr/local/bin/script.sh"]
