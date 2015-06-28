FROM debian:jessie
MAINTAINER EverydayHero <edh-dev@everydayhero.com.au>

RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
RUN echo "deb-src http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list

ENV NGINX_VERSION 1.9.2-1~jessie
ENV NGINX_SOURCE_FOLDER nginx-1.9.2

RUN apt-get update && apt-get install -y \
  adduser \
  git \
  build-essential \
  geoip-database \
  libgeoip-dev \
  libgeoip1 \
  python \
  unzip

RUN git clone https://github.com/streadway/ngx_txid.git /tmp/ngx_txid
RUN git clone https://github.com/zebrafishlabs/nginx-statsd.git /tmp/nginx-statsd
RUN apt-get build-dep -y nginx=${NGINX_VERSION}

# TODO use a patch, rather than a replacement 'rules'
COPY rules /tmp/rules
COPY update_changelog.sh /tmp/update_changelog.sh
COPY get-pip.py /tmp/get-pip.py

RUN cd /tmp && apt-get source nginx=${NGINX_VERSION} && \
  cp rules /tmp/${NGINX_SOURCE_FOLDER}/debian/rules && \
  /tmp/update_changelog.sh

RUN python /tmp/get-pip.py && pip install envtpl

RUN cd /tmp/${NGINX_SOURCE_FOLDER} && \
  dpkg-buildpackage -uc -b

RUN cd /tmp && dpkg -i nginx_*.deb && \
  rm -rf /tmp && \
  rm -rf /var/lib/apt/lists/*

ADD http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz /etc/geoip/
RUN gunzip /etc/geoip/GeoIP.dat.gz
RUN cp /etc/geoip/GeoIP.dat /usr/share/GeoIP/GeoIP.dat

ADD test /usr/local/bin/test
ADD serve /usr/local/bin/serve

EXPOSE 80 443

CMD ["serve"]
