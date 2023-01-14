#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# shellcheck disable=SC2086
# shellcheck disable=SC2006
function log() {
    echo "[Mount] ${1}"
}
function logdocker() {
    echo "[DOCKER] ${1}"
}
apk add docker-cli --quiet --no-cache --force-refresh --no-progress
log "-> starting mounts part <-"
SMOUNT=/config/scripts
SLOG=/config/logs
SRC=/config/rc-refresh
IFS=$'\n'
filter="$1"
config=/config/rclone/rclone-docker.conf
POINTS="unionfs remotes"
for mount in ${POINTS};do
    command=$(mountpoint -q /mnt/$mount && echo true || echo false)
    if [[ $command == "false" ]];then fusermount -uzq /mnt/$mount 1>/dev/null 2>&1;fi
done
if [[ -f "/config/scripts/union-mount.sh" ]];then
   bash /config/scripts/union-mount.sh
fi
sleep 5

log "MERGERFS PID: ${MERGERFS_PID}"

while true; do
   MERGERFS_PID=$(pgrep mergerfs)
   if [ "${MERGERFS_PID}" ] && [ -e /proc/${MERGERFS_PID} ]; then
      sleep 20 && echo "rclone_union and mergerfs is mounted since $(date)"
      continue
   else
      sleep 5 && crashed
      exit 0
  fi
done
#EOF#