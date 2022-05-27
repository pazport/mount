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
function startupdocker() {
while true; do
   MERGERFS_PID=$(pgrep mergerfs)
   if [[ "${MERGERFS_PID}" ]]; then
      restart_container
      break
   else
      sleep 5 && log "waiting for running megerfs"
      continue
  fi
done
}
function crashed() {
logdocker " -------------------------------"
logdocker " -->      STOP DOCKERS      <---"
logdocker " -->    MERGERFS CRASHED    <---"
logdocker " -------------------------------"
container=$(docker ps -aq --format '{{.Names}}' | sed '/^$/d' | grep -E 'ple|arr|emby|jelly')
docker stop $container >> /dev/null
sleep 2
}
function restart_container() {
logdocker " -------------------------------"
logdocker " -->   RESTART DOCKER PART  <---"
logdocker " -->         STARTED        <---"
logdocker " -------------------------------"
container=$(docker ps -aq --format '{{.Names}}' | sed '/^$/d' | grep -E 'ple|arr|emby|jelly')
docker stop $container >> /dev/null
logdocker " -->> sleeping 5secs for graceful stopped containers <<--"
sleep 5
container=$(docker ps -aq --format '{{.Names}}' | sed '/^$/d' | grep -E 'ple|arr|emby|jelly')
#### LIST SOME DOCKER TO RESTART ####
docker start $container >> /dev/null
logdocker " -------------------------------"
logdocker " -->   RESTART DOCKER PART  <---"
logdocker " -->        FINISHED        <---"
logdocker " -------------------------------"
}
#### END OF FUNCTION #####
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
    command=$(mountpoint -q /mnt/unionfs && echo true || echo false)
    if [[ $command == "false" ]];then fusermount -uzq /mnt/unionfs 1>/dev/null 2>&1;fi
done
if [[ ! -d "/mnt/unionfs" ]];then mkdir -p /mnt/unionfs;fi
if [[ -f "/config/scripts/union-mount.sh" ]];then
   bash /config/scripts/union-mount.sh
fi
sleep 5
UFSPATH=$(cat /tmp/rclone-mount.file)
rm -rf /tmp/mergerfs_mount_file && touch /tmp/mergerfs_mount_file
echo -e "allow_other,rw,async_read=false,use_ino,func.getattr=newest,category.action=all,category.create=ff,cache.files=partial,dropcacheonclose=true,nonempty,minfreespace=0,fsname=mergerfs" >> /tmp/mergerfs_mount_file
MGFS=$(cat /tmp/mergerfs_mount_file)
mergerfs -o ${MGFS} ${UFSPATH} /mnt/unionfs
sleep 5
#### CHECK DOCKER.SOCK ####
dockersock=$(curl --silent --output /dev/null --show-error --fail --unix-socket /var/run/docker.sock http://localhost/images/json)
#### RESTART DOCKER #### 
if [[ "${dockersock}" != '' ]];then
   sleep 1
   logdocker " [ WARNING ] SOME APPS NEED A RESTART [ WARNING ]"
   logdocker "   SAMPLE :"
   logdocker "   PLEX / SONARR / LIDARR / RADARR / EMBY"
   logdocker " [ WARNING ] SOME APPS NEED A RESTART [ WARNING ]"
   sleep 30
else
   startupdocker
fi

MERGERFS_PID=$(pgrep mergerfs)

log "MERGERFS PID: ${MERGERFS_PID}"

while true; do
   MERGERFS_PID=$(pgrep mergerfs)
   if [ "${MERGERFS_PID}" ] && [ -e /proc/${MERGERFS_PID} ]; then
      sleep 5 && echo "rclone_union and mergerfs is mounted since $(date)"
      continue
   else
      sleep 5 && crashed
      exit 0
  fi
done
#EOF#