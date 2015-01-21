FROM ubuntu:14.04
MAINTAINER EverydayHero <edh-dev@everydayhero.com.au>

ENV APT_UPDATED 20150121
RUN apt-get update
RUN apt-get install -y nginx
ADD http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz /etc/geoip/
RUN gunzip /etc/geoip/GeoIP.dat.gz

EXPOSE 80

CMD ["/usr/sbin/nginx"]
