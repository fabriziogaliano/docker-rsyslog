# docker-rsyslog
[![](https://images.microbadger.com/badges/image/fabriziogaliano/docker-rsyslog.svg)](https://microbadger.com/images/fabriziogaliano/docker-rsyslog "Get your own image badge on microbadger.com") [![](https://images.microbadger.com/badges/version/fabriziogaliano/docker-rsyslog.svg)](https://microbadger.com/images/fabriziogaliano/docker-rsyslog "Get your own version badge on microbadger.com")

Docker RSyslog for collecting - divide and forward Log ( in TLS ) from containers

## Quick start

# Run docker on Local-RemoteForwarder

```
docker run -d -p 514:514:udp fabriziogaliano/docker-rsyslog
```

# Run docker on Concentrator-Incoming 

```
docker run -d -p 10514:10514 fabriziogaliano/docker-rsyslog
```


## Example Docker-Compose file for Local-Forwarder (Strongly adviced)

```
version: '2'
services:
   rsyslog:
       image: fabriziogaliano/docker-rsyslog

       container_name: rsyslog-local-forward

       volumes:
          - "./etc/rsyslog.conf:/etc/rsyslog.conf"
          - "./rsyslog.d:/etc/rsyslog.d"
          - "./logs:/var/log"
          - "./spool:/var/spool/rsyslog"

       ports:
          - "514:514/udp"

       restart: always
```

## Example Docker-Compose file for Concentrator-Incoming (Strongly adviced)

```
version: '2'
services:
   rsyslog:
       image: fabriziogaliano/docker-rsyslog

       container_name: rsyslog-incoming

       volumes:
          - "./etc/rsyslog.conf:/etc/rsyslog.conf"
          - "./rsyslog.d:/etc/rsyslog.d"
          - "./logs:/var/log"
          - "./certs-tls:/etc/certs-tls"

       ports:
          - "10514:10514"

       restart: always
```

## Configuration of the docker-compose file for the syslog log driver

```
logging:
         driver: syslog
         options:
           tag: prod/moduleId
           syslog-address: "udp://rlog.example.com:514"
```

## Advanced Configuration for Rsyslog, there are 3 config file very usefull on this image:

# Collecting and divide log Locally [ 30-docker.conf ]

```
$FileCreateMode 0644
template(name="DockerLogFileName" type="list") {
   constant(value="/var/log/docker/")
   property(name="syslogtag" securepath="replace" \
            regex.expression="dev/\\(.*\\)\\[" regex.submatch="1")
   constant(value="/docker.log")
}

/var/log/docker/combined.log
if $syslogtag contains 'dev/' then ?DockerLogFileName

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
   target="rlog.example.com"
   port="10514"
   template="RemoteForwardFormat"
   queue.SpoolDirectory="/var/spool/rsyslog"
   queue.FileName="remoteQueueForwarding"
   queue.MaxDiskSpace="1g"
   queue.SaveOnShutdown="on"
   queue.Type="Disk"
   ResendLastMSGOnReconnect="on"
   )
```

# Accept incoming log from remote server [ 35-incoming-logs ] ( enable this configuration only on concentrator server )

```
template(name="PerHostDockerProdLogFileName" type="list") {
   constant(value="/var/log/remote/docker/prod/")
   property(name="syslogtag" securepath="replace" \
   regex.expression="prod/\\(.*\\)\\[" regex.submatch="1")
   constant(value="/docker.log")
}
template(name="PerHostDockerDevLogFileName" type="list") {
   constant(value="/var/log/remote/docker/dev/")
   property(name="syslogtag" securepath="replace" \
   regex.expression="dev/\\(.*\\)\\[" regex.submatch="1")
   constant(value="/docker.log")
}
template(name="PerHostDockerCombinedLogFileName" type="list") {
   constant(value="/var/log/remote/")
   property(name="$year" securepath="replace")
   constant(value="/docker/combined.log")
}

ruleset(name="remote") {
   $FileCreateMode 0644
   $DirCreateMode 0755
   if $syslogtag contains 'prod/' then {
      ?PerHostDockerProdLogFileName
      /var/log/remote/docker/prod/combined.log
     }

   if $syslogtag contains 'dev/' then {
      ?PerHostDockerDevLogFileName
      /var/log/remote/docker/dev/combined.log
     }
}
```
