FROM alpine:3.23

RUN apk add --no-cache nginx openssl && \
    mkdir -p /etc/nginx/ssl

COPY ./conf/nginx.conf /etc/nginx/nginx.conf
COPY ./tools/script.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/script.sh

EXPOSE 443

CMD ["/usr/local/bin/script.sh"]
