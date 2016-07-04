FROM quay.io/everydayhero/base:0.1
MAINTAINER Everydayhero Engineering "edh-dev@everydayhero.com.au"

ADD build.sh /tmp
RUN /tmp/build.sh

RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

ADD test  /usr/local/bin/test
ADD serve /usr/local/bin/serve

CMD ["nginx", "-g", "daemon off;"]
