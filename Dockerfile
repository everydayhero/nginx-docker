FROM everydayhero/ubuntu:16.04
MAINTAINER Everydayhero Engineering "edh-dev@everydayhero.com.au"

ADD test  /usr/local/bin/test
ADD serve /usr/local/bin/serve

ADD build.sh /tmp
RUN /tmp/build.sh

CMD ["serve"]
