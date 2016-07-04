FROM quay.io/everydayhero/base:0.1
MAINTAINER Everydayhero Engineering "edh-dev@everydayhero.com.au"

ADD test  /usr/local/bin/test
ADD serve /usr/local/bin/serve

ADD build.sh /tmp
RUN /tmp/build.sh

CMD ["nginx", "-g", "daemon off;"]
