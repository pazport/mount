FROM ghcr.io/linuxserver/baseimage-alpine:3.13

RUN \
  echo "**** install build packages ****" && \
  apk --quiet --no-cache --no-progress add bash bc findutils coreutils && \
  rm -rf /var/cache/apk/*

VOLUME [ "/config" ]

COPY root/ /
COPY root/mclone/mclone /usr/bin/
EXPOSE 8080

# Setup EntryPoint
ENTRYPOINT [ "/init" ]