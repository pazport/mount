#!/usr/bin/with-contenv bash
# shellcheck shell=bash
function log() {
echo "[UPDATE] ${1}"
}
# function source start
log "-> update rclone || start <-"

if [[ -x $(command -v rclone) ]];then
    rclone selfupdate --config=/config/rclone/rclone-docker.conf --stable
    chown -cf abc:abc /root/
fi
log "-> update rclone || done <-"

log "-> update packages || start <-"
update="update upgrade fix"
for up2 in ${update};do
   apk --quiet --no-cache --no-progress $up2
done
    apk del --quiet --clean-protected --no-progress
    rm -rf /var/cache/apk/*
log "-> update packages || done <-"
#<EOF>#
