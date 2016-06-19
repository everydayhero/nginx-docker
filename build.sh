#!/bin/sh

set -euo

export NGINX_VERSION=1.11.0
export NDK_VERSION=0.3.0
export VTS_VERSION=0.1.9
export SETMISC_VERSION=0.30
export LUA_VERSION=0.10.3
export STICKY_SESSIONS_VERSION=c78b7dd79d0d
export LUA_CJSON_VERSION=2.1.0.4
export LUA_RESTY_HTTP_VERSION=0.07
export LUA_UPSTREAM_VERSION=0.05
export MORE_HEADERS_VERSION=0.30
export NAXSI_VERSION=0.55rc1
export NGINX_DIGEST_AUTH=f85f5d6fdcc06002ff879f5cbce930999c287011
export NGINX_SUBSTITUTIONS=bc58cb11844bc42735bbaef7085ea86ace46d05b
export NGINX_STATSD=b756a12abf110b9e36399ab7ede346d4bb86d691
export NGINX_TXID=f1c197cb9c42e364a87fbb28d5508e486592ca42

export BUILD_PATH=/tmp/build

get_src() {
  local sha="$1"
  local url="$2"
  local f=$(basename "$url")

  curl -sSL "$url" -o "$f"
  echo "$sha  $f" | sha256sum -c - || exit 10
  tar xzf "$f"
  rm -rf "$f"
}

mkdir "$BUILD_PATH"
cd "$BUILD_PATH"

# install required packages to build
apt-get update && apt-get install --no-install-recommends -y \
  bash \
  build-essential \
  ca-certificates \
  curl \
  libaio-dev \
  libaio1 \
  libgeoip-dev \
  libgeoip-dev \
  libgeoip1 \
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
  zlib1g-dev || exit 1

# Download, verify and extract the source files
get_src 6ca0e7bf540cdae387ce9470568c2c3a826bc7e7f12def1ae7d20b66f4065a99 \
        "http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz"

get_src 88e05a99a8a7419066f5ae75966fb1efc409bad4522d14986da074554ae61619 \
        "https://github.com/simpl/ngx_devel_kit/archive/v$NDK_VERSION.tar.gz"

get_src 59920dd3f92c2be32627121605751b52eae32b5884be09f2e4c53fb2fae8aabc \
        "https://github.com/openresty/set-misc-nginx-module/archive/v$SETMISC_VERSION.tar.gz"

get_src ddd297a5f894d966cae19f112c79f99ec9fa13612c3d324c19533247c4953980 \
        "https://github.com/vozlt/nginx-module-vts/archive/v$VTS_VERSION.tar.gz"

get_src a69504c25de67bce968242d331d2e433c021405a6dba7bca0306e6e0b040bb50 \
        "https://github.com/openresty/lua-nginx-module/archive/v$LUA_VERSION.tar.gz"

get_src 5417991b6db4d46383da2d18f2fd46b93fafcebfe87ba87f7cfeac4c9bcb0224 \
        "https://github.com/openresty/lua-cjson/archive/$LUA_CJSON_VERSION.tar.gz"

get_src 1c6aa06c9955397c94e9c3e0c0fba4e2704e85bee77b4512fb54ae7c25d58d86 \
        "https://github.com/pintsized/lua-resty-http/archive/v$LUA_RESTY_HTTP_VERSION.tar.gz"

get_src 2aad309a9313c21c7c06ee4e71a39c99d4d829e31c8b3e7d76f8c964ea8047f5 \
        "https://github.com/openresty/headers-more-nginx-module/archive/v$MORE_HEADERS_VERSION.tar.gz"

get_src 0fdfb17083598e674680d8babe944f48a9ccd2af9f982eda030c446c93cfe72b \
        "https://github.com/openresty/lua-upstream-nginx-module/archive/v$LUA_UPSTREAM_VERSION.tar.gz"

get_src 6353441ee53dca173689b63a78f1c9ac5408f3ed066ddaa3f43fd2795bd43cdd \
        "https://github.com/nbs-system/naxsi/archive/$NAXSI_VERSION.tar.gz"

get_src 8b1277e41407e893b5488bd953612f4e7bf9e241f9494faf71d93f1b1d5beefa \
        "https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng/get/$STICKY_SESSIONS_VERSION.tar.gz"

get_src 618de9d87cbb4e6ad21cc4a1a178bbfdabddba9ad07ddee4c1190d23c12887ee \
        "https://github.com/atomx/nginx-http-auth-digest/archive/$NGINX_DIGEST_AUTH.tar.gz"

get_src 8eabbcd5950fdcc718bb0ef9165206c2ed60f67cd9da553d7bc3e6fe4e338461 \
        "https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/$NGINX_SUBSTITUTIONS.tar.gz"

get_src 01e01b48addd87d75b1ccb830eecc5824b625c816b3e6fd93107247f00a95ab8 \
        "https://github.com/zebrafishlabs/nginx-statsd/archive/$NGINX_STATSD.tar.gz"

get_src c5c14172cf23e572d2258bbbbdf09ae7a81a7b6503ce1a0efe0f76260a9a86c5 \
        "https://github.com/streadway/ngx_txid/archive/$NGINX_TXID.tar.gz"

# Patch Statsd module
cd "$BUILD_PATH/nginx-statsd-$NGINX_STATSD"
curl https://patch-diff.githubusercontent.com/raw/zebrafishlabs/nginx-statsd/pull/20.patch | patch -p1

# Build Nginx
cd "$BUILD_PATH/nginx-$NGINX_VERSION"

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
  --add-module="$BUILD_PATH/ngx_devel_kit-$NDK_VERSION" \
  --add-module="$BUILD_PATH/set-misc-nginx-module-$SETMISC_VERSION" \
  --add-module="$BUILD_PATH/nginx-module-vts-$VTS_VERSION" \
  --add-module="$BUILD_PATH/lua-nginx-module-$LUA_VERSION" \
  --add-module="$BUILD_PATH/headers-more-nginx-module-$MORE_HEADERS_VERSION" \
  --add-module="$BUILD_PATH/nginx-goodies-nginx-sticky-module-ng-$STICKY_SESSIONS_VERSION" \
  --add-module="$BUILD_PATH/nginx-http-auth-digest-$NGINX_DIGEST_AUTH" \
  --add-module="$BUILD_PATH/ngx_http_substitutions_filter_module-$NGINX_SUBSTITUTIONS" \
  --add-module="$BUILD_PATH/ngx_txid-$NGINX_TXID" \
  --add-module="$BUILD_PATH/nginx-statsd-$NGINX_STATSD" \
  --add-module="$BUILD_PATH/lua-upstream-nginx-module-$LUA_UPSTREAM_VERSION" || exit 1 \
  && make || exit 1 \
  && make install || exit 1

echo "Installing CJSON module"
cd "$BUILD_PATH/lua-cjson-$LUA_CJSON_VERSION"
make LUA_INCLUDE_DIR=/usr/include/luajit-2.0 && make install

echo "Installing lua-resty-http module"
# copy lua module
cd "$BUILD_PATH/lua-resty-http-$LUA_RESTY_HTTP_VERSION"
sed -i 's/resty.http_headers/http_headers/' $BUILD_PATH/lua-resty-http-$LUA_RESTY_HTTP_VERSION/lib/resty/http.lua
cp $BUILD_PATH/lua-resty-http-$LUA_RESTY_HTTP_VERSION/lib/resty/http.lua         /usr/local/lib/lua/5.1
cp $BUILD_PATH/lua-resty-http-$LUA_RESTY_HTTP_VERSION/lib/resty/http_headers.lua /usr/local/lib/lua/5.1

echo "Installing GeoIP database"
mkdir /etc/geoip /usr/share/GeoIP
curl -sSL http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz -o /etc/geoip/GeoIP.dat.gz
gunzip /etc/geoip/GeoIP.dat.gz
cp /etc/geoip/GeoIP.dat /usr/share/GeoIP/GeoIP.dat


echo "Cleaning..."

cd /

apt-mark unmarkauto \
  bash \
  curl ca-certificates \
  libgeoip1 \
  libpcre3 \
  zlib1g \
  libaio1 \
  luajit \
  libluajit-5.1-2 \
  xz-utils \
  geoip-bin \
  openssl

apt-get remove -y --purge \
  build-essential \
  gcc-5 \
  cpp-5 \
  libgeoip-dev \
  libpcre3-dev \
  libssl-dev \
  zlib1g-dev \
  libaio-dev \
  libluajit-5.1-dev \
  linux-libc-dev \
  linux-headers-generic

apt-get autoremove -y

mkdir -p /var/lib/nginx/body /usr/share/nginx/html

mv /usr/share/nginx/sbin/nginx /usr/sbin

rm -rf "$BUILD_PATH"
rm -Rf /usr/share/man /usr/share/doc
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
