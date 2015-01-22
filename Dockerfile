FROM ubuntu:14.04
MAINTAINER EverydayHero <edh-dev@everydayhero.com.au>

RUN apt-get update && apt-get install -y  \
        geoip-database \
        libgeoip1 \
        nginx-full \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 80

CMD ["/usr/sbin/nginx"]
