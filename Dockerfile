FROM ghcr.io/linuxserver/baseimage-alpine:3.14

RUN \
  echo "**** install build packages ****" && \
  apk --quiet --no-cache --no-progress add bash bc findutils coreutils shadow-conv

VOLUME [ "/config" ]

COPY root/ /

EXPOSE 8080

# Setup EntryPoint
ENTRYPOINT [ "/init" ]
