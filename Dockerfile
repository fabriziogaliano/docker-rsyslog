FROM alpine:3.4

MAINTAINER Fabrizio Galiano <fabrizio.galiano@hotmail.com>

RUN  apk add --update rsyslog \
  && rm -rf /var/cache/apk/*

RUN mkdir -p /var/log/docker \
    && mkdir -p /var/log/docker/no_tag/ \
    && mkdir -p /var/log/remote/ \
    && chmod 777 /var/log/docker -R && chmod 777 /var/log/remote/ -R

EXPOSE 514 514/udp

VOLUME [ "/var/log", "/etc/rsyslog.d" ]

# for some reason, the apk comes built with a v5
# config file. using this one for v8:
COPY ./etc/rsyslog.conf /etc/rsyslog.conf

ENTRYPOINT [ "rsyslogd", "-n" ]
