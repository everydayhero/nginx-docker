#!/bin/bash

set -euo pipefail

export NGINX_VERSION=1.11.3
export NAXSI_VERSION=0.55.1
export NGINX_STATSD=07dcefdab2838b5aa68f1233a44fedcda8052b7f

export BUILD_PATH=/tmp/build

get_src() {
  local sha="$1"
  local url="$2"
  local file=$(basename "$url")

  curl -sSL "$url" -o "$file"
  echo "$sha  $file" | sha256sum -c - || exit 10
  tar xzf "$file"
  rm -rf "$file"
}

mkdir -p "$BUILD_PATH"
cd "$BUILD_PATH"

echo "==> Installing build dependencies"
apt-get update
apt-get install --no-install-recommends -y \
  build-essential \
  ca-certificates \
  curl \
  libaio-dev \
  libaio1 \
  libgeoip-dev \
  libgeoip1 \
  libluajit-5.1 \
  libluajit-5.1-dev \
  libpcre3 \
  libpcre3-dev \
  libssl-dev \
  linux-headers-generic \
  luajit \
  lzma \
  openssl \
  patch \
  zlib1g \
  zlib1g-dev

# Download, verify and extract the source files
get_src 4a667f40f9f3917069db1dea1f2d5baa612f1fa19378aadf71502e846a424610 \
        "http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz"

get_src fed822e3f507801ce44964908eb1dca8ec58dc0a9bc47f7e7d00c6c4ef97f78b \
        "https://github.com/nbs-system/naxsi/archive/$NAXSI_VERSION.tar.gz"

get_src 847f52948f557b88ff2637c22271eba4ba631678d24cbdfa66b1f29d055c7f0d \
        "https://github.com/zebrafishlabs/nginx-statsd/archive/$NGINX_STATSD.tar.gz"

cd "$BUILD_PATH/nginx-$NGINX_VERSION"

echo "==> Compiling"
./configure \
  --prefix=/usr/share/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --http-log-path=/var/log/nginx/access.log \
  --error-log-path=/var/log/nginx/error.log \
  --lock-path=/var/lock/nginx.lock \
  --pid-path=/run/nginx.pid \
  --http-client-body-temp-path=/var/lib/nginx/body \
  --http-proxy-temp-path=/var/lib/nginx/proxy \
  --with-file-aio \
  --with-http_addition_module \
  --with-http_auth_request_module \
  --with-http_dav_module \
  --with-http_geoip_module \
  --with-http_gzip_static_module \
  --with-http_realip_module \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_sub_module \
  --with-http_v2_module \
  --with-ipv6 \
  --with-pcre-jit \
  --with-stream \
  --with-stream_ssl_module \
  --with-threads \
  --without-http_autoindex_module \
  --without-http_charset_module \
  --without-http_empty_gif_module \
  --without-http_fastcgi_module \
  --without-http_memcached_module \
  --without-http_scgi_module \
  --without-http_ssi_module \
  --without-http_userid_module \
  --without-http_uwsgi_module \
  --without-mail_imap_module \
  --without-mail_pop3_module \
  --without-mail_smtp_module \
  --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic' \
  --add-module="$BUILD_PATH/naxsi-$NAXSI_VERSION/naxsi_src/" \
  --add-module="$BUILD_PATH/nginx-statsd-$NGINX_STATSD"

make
make install

echo "==> Installing GeoIP database"
mkdir -p /usr/share/GeoIP
curl -sSL -o /usr/share/GeoIP/GeoIP.dat.gz http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
gunzip /usr/share/GeoIP/GeoIP.dat.gz

echo "==> Cleaning up..."

cd /

apt-mark unmarkauto \
  bash \
  ca-certificates \
  curl \
  geoip-bin \
  libaio1 \
  libgeoip1 \
  libluajit-5.1-2 \
  libpcre3 \
  luajit \
  openssl \
  xz-utils \
  zlib1g

apt-get remove -y --purge \
  build-essential \
  cpp-5 \
  gcc-5 \
  libaio-dev \
  libgeoip-dev \
  libluajit-5.1-dev \
  libpcre3-dev \
  libssl-dev \
  linux-headers-generic \
  linux-libc-dev \
  perl-modules-5.22 \
  zlib1g-dev

apt-get autoremove -y

mkdir -p /var/lib/nginx/body /usr/share/nginx/html

mv /usr/share/nginx/sbin/nginx /usr/sbin

rm -rf "$BUILD_PATH"
rm -rf /usr/share/{man,doc}
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/apt/archives/*
