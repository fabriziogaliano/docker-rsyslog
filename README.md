# docker-rsyslog

Docker RSyslog for collecting - divide and forward Log from containers

## Quick Start

```
docker run -d -p 514:514 -p 514:514/udp fabriziogaliano/rsyslog
```

## Docker-Compose file (Strongly adviced)

```
version: '2'
services:
   rsyslog:
       image: fabriziogaliano/rsyslog

       container_name: rsyslog

       volumes:
          - "./etc/rsyslog.conf:/etc/rsyslog.conf"
          - "./rsyslog.d:/etc/rsyslog.d"
          - "./logs:/var/log"

       ports:
          - "514:514"
          - "514:514/udp"

       restart: always
```

## Configuration of the log driver

```
logging:
         driver: syslog
         options:
           tag: docker/custom-image-name
           syslog-address: "tcp://rsyslog.example.com:514"
```

## Advanced Configuration for Rsyslog

There are 3 config file very usefull on this image:

# Collecting and divide log Locally [ 30-docker.conf ]

```
$FileCreateMode 0644
template(name="DockerLogFileName" type="list") {
   constant(value="/var/log/docker/")
   property(name="syslogtag" securepath="replace" \
            regex.expression="docker/\\(.*\\)\\[" regex.submatch="1")
   constant(value="/docker.log")
}
if $programname == 'docker' then \
  /var/log/docker/combined.log
if $programname == 'docker' then \
  if $syslogtag contains 'docker/' then \
    ?DockerLogFileName
  else
    /var/log/docker/no_tag/docker.log
$FileCreateMode 0600
```

# Forward Log to Concentrator Server [ 35-remote-logging ]

```
template(name="RemoteForwardFormat" type="list") {
    constant(value="<")
    property(name="pri")
    constant(value=">")
    property(name="timestamp" dateFormat="rfc3339")
    constant(value=" ")
    property(name="hostname")
    constant(value=" ")
    property(name="syslogtag")
    property(name="msg" spifno1stsp="on")
    property(name="msg")
}
action(
   type="omfwd"
   protocol="tcp"
   target="rsyslog.example.com"
   port="514"
   template="RemoteForwardFormat"
   queue.SpoolDirectory="/var/spool/rsyslog"
   queue.FileName="remote"
   queue.MaxDiskSpace="1g"
   queue.SaveOnShutdown="on"
   queue.Type="LinkedList"
   ResendLastMSGOnReconnect="on"
   )
```

# Accept incoming log from remote server [ 35-incoming-logs ] ( up this configuration only on concentrator server )

```
$ModLoad imtcp
input(type="imtcp" port="514" ruleset="remote")
template(name="PerHostDockerLogFileName" type="list") {
   constant(value="/var/log/remote/")
   property(name="hostname" securepath="replace")
   constant(value="/")
   property(name="$year")
   constant(value="/")
   property(name="$month")
   constant(value="/")
   property(name="$day")
   constant(value="/docker/")
   property(name="syslogtag" securepath="replace" \
   regex.expression="docker/\\(.*\\)\\[" regex.submatch="1")
   constant(value="/docker.log")
}
template(name="PerHostDockerCombinedLogFileName" type="list") {
   constant(value="/var/log/remote/")
   property(name="hostname" securepath="replace")
   constant(value="/")
   property(name="$year")
   constant(value="/")
   property(name="$month")
   constant(value="/")
   property(name="$day")
   constant(value="/docker/combined.log")
```
