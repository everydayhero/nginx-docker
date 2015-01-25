FROM debian:wheezy
MAINTAINER EverydayHero <edh-dev@everydayhero.com.au>

RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
RUN echo "deb http://nginx.org/packages/mainline/debian/ wheezy nginx" >> /etc/apt/sources.list
RUN echo "deb-src http://nginx.org/packages/mainline/debian/ wheezy nginx" >> /etc/apt/sources.list

ENV NGINX_VERSION 1.7.9-1~wheezy
ENV NGINX_SOURCE_FOLDER nginx-1.7.9

RUN apt-get update && apt-get install -y \
  build-essential \
  dpkg-dev \
  geoip-database \
  libgeoip-dev \
  libgeoip1 \
  libpcre3 \
  libpcre3-dev \
  nginx \
  unzip \
  zlib1g-dev && \
  apt-get build-dep -y nginx=${NGINX_VERSION}

WORKDIR /tmp
RUN apt-get source nginx=${NGINX_VERSION}
COPY rules /tmp/${NGINX_SOURCE_FOLDER}/debian/rules
COPY changelog /tmp/${NGINX_SOURCE_FOLDER}/debian/changelog

WORKDIR /tmp/${NGINX_SOURCE_FOLDER}
RUN dpkg-buildpackage -uc -b

WORKDIR /tmp
RUN dpkg -i nginx_1.7.9-2~wheezy_amd64.deb nginx-dbg_1.7.9-2~wheezy_amd64.deb

ADD http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz /etc/geoip/
RUN gunzip /etc/geoip/GeoIP.dat.gz

EXPOSE 80 443

CMD ["/usr/sbin/nginx"]
