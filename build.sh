#!/bin/bash

set -euo pipefail

export NGINX_VERSION=1.11.1
export NDK_VERSION=0.3.0
export VTS_VERSION=0.1.9
export SETMISC_VERSION=0.30
export LUA_VERSION=0.10.3
export LUA_CJSON_VERSION=2.1.0.4
export LUA_RESTY_HTTP_VERSION=0.07
export LUA_UPSTREAM_VERSION=0.05
export MORE_HEADERS_VERSION=0.30
export NAXSI_VERSION=0.55rc1
export NGINX_STATSD=b756a12abf110b9e36399ab7ede346d4bb86d691
export NGINX_TXID=f1c197cb9c42e364a87fbb28d5508e486592ca42

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
  openssl \
  patch \
  zlib1g \
  zlib1g-dev

echo "==> Fetching Nginx dependencies"

get_src 5d8dd0197e3ffeb427729c045382182fb28db8e045c635221b2e0e6722821ad0 \
        "http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz"

get_src 88e05a99a8a7419066f5ae75966fb1efc409bad4522d14986da074554ae61619 \
        "https://github.com/simpl/ngx_devel_kit/archive/v$NDK_VERSION.tar.gz"

get_src ddd297a5f894d966cae19f112c79f99ec9fa13612c3d324c19533247c4953980 \
        "https://github.com/vozlt/nginx-module-vts/archive/v$VTS_VERSION.tar.gz"

get_src a69504c25de67bce968242d331d2e433c021405a6dba7bca0306e6e0b040bb50 \
        "https://github.com/openresty/lua-nginx-module/archive/v$LUA_VERSION.tar.gz"

get_src 5417991b6db4d46383da2d18f2fd46b93fafcebfe87ba87f7cfeac4c9bcb0224 \
        "https://github.com/openresty/lua-cjson/archive/$LUA_CJSON_VERSION.tar.gz"

get_src 1c6aa06c9955397c94e9c3e0c0fba4e2704e85bee77b4512fb54ae7c25d58d86 \
        "https://github.com/pintsized/lua-resty-http/archive/v$LUA_RESTY_HTTP_VERSION.tar.gz"

get_src 0fdfb17083598e674680d8babe944f48a9ccd2af9f982eda030c446c93cfe72b \
        "https://github.com/openresty/lua-upstream-nginx-module/archive/v$LUA_UPSTREAM_VERSION.tar.gz"

get_src 2aad309a9313c21c7c06ee4e71a39c99d4d829e31c8b3e7d76f8c964ea8047f5 \
        "https://github.com/openresty/headers-more-nginx-module/archive/v$MORE_HEADERS_VERSION.tar.gz"

get_src 6353441ee53dca173689b63a78f1c9ac5408f3ed066ddaa3f43fd2795bd43cdd \
        "https://github.com/nbs-system/naxsi/archive/$NAXSI_VERSION.tar.gz"

get_src 01e01b48addd87d75b1ccb830eecc5824b625c816b3e6fd93107247f00a95ab8 \
        "https://github.com/zebrafishlabs/nginx-statsd/archive/$NGINX_STATSD.tar.gz"

get_src c5c14172cf23e572d2258bbbbdf09ae7a81a7b6503ce1a0efe0f76260a9a86c5 \
        "https://github.com/streadway/ngx_txid/archive/$NGINX_TXID.tar.gz"

# Patch nginx-statsd module to work with Nginx 1.10+
cd "$BUILD_PATH/nginx-statsd-$NGINX_STATSD"
curl https://patch-diff.githubusercontent.com/raw/zebrafishlabs/nginx-statsd/pull/20.patch | patch -p1

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
  --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
  --http-proxy-temp-path=/var/lib/nginx/proxy \
  --http-scgi-temp-path=/var/lib/nginx/scgi \
  --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
  --with-debug \
  --with-pcre-jit \
  --with-ipv6 \
  --with-http_auth_request_module \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_realip_module \
  --with-http_auth_request_module \
  --with-http_addition_module \
  --with-http_dav_module \
  --with-http_geoip_module \
  --with-http_gzip_static_module \
  --with-http_sub_module \
  --with-http_v2_module \
  --with-stream \
  --with-stream_ssl_module \
  --with-threads \
  --with-file-aio \
  --without-mail_pop3_module \
  --without-mail_smtp_module \
  --without-mail_imap_module \
  --without-http_uwsgi_module \
  --without-http_scgi_module \
  --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic' \
  --add-module="$BUILD_PATH/naxsi-$NAXSI_VERSION/naxsi_src" \
  --add-module="$BUILD_PATH/ngx_devel_kit-$NDK_VERSION" \
  --add-module="$BUILD_PATH/nginx-module-vts-$VTS_VERSION" \
  --add-module="$BUILD_PATH/lua-nginx-module-$LUA_VERSION" \
  --add-module="$BUILD_PATH/lua-upstream-nginx-module-$LUA_UPSTREAM_VERSION" \
  --add-module="$BUILD_PATH/headers-more-nginx-module-$MORE_HEADERS_VERSION" \
  --add-module="$BUILD_PATH/ngx_txid-$NGINX_TXID" \
  --add-module="$BUILD_PATH/nginx-statsd-$NGINX_STATSD"

make
make install

echo "==> Installing CJSON module"
cd "$BUILD_PATH/lua-cjson-$LUA_CJSON_VERSION"
make LUA_INCLUDE_DIR=/usr/include/luajit-2.0
make install

echo "==> Installing lua-resty-http module"
cd "$BUILD_PATH/lua-resty-http-$LUA_RESTY_HTTP_VERSION"
sed -i 's/resty.http_headers/http_headers/' $BUILD_PATH/lua-resty-http-$LUA_RESTY_HTTP_VERSION/lib/resty/http.lua
cp $BUILD_PATH/lua-resty-http-$LUA_RESTY_HTTP_VERSION/lib/resty/http.lua         /usr/local/lib/lua/5.1
cp $BUILD_PATH/lua-resty-http-$LUA_RESTY_HTTP_VERSION/lib/resty/http_headers.lua /usr/local/lib/lua/5.1

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
