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
container=$(docker ps -aq --format '{{.Names}}' | sed '/^$/d' | grep -E 'plex|arr|emby|jelly')
docker stop $container >> /dev/null
sleep 2
}
function restart_container() {
logdocker " -------------------------------"
logdocker " -->   RESTART DOCKER PART  <---"
logdocker " -->         STARTED        <---"
logdocker " -------------------------------"
container=$(docker ps -aq --format '{{.Names}}' | sed '/^$/d' | grep -E 'plex|arr|emby|jelly')
docker stop $container >> /dev/null
logdocker " -->> sleeping 5secs for graceful stopped containers <<--"
sleep 5
container=$(docker ps -aq --format '{{.Names}}' | sed '/^$/d' | grep -E 'plex|arr|emby|jelly')
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
    command=$(mountpoint -q /mnt/$mount && echo true || echo false)
    if [[ $command == "false" ]];then fusermount -uzq /mnt/$mount 1>/dev/null 2>&1;fi
done
if [[ ! -d "/mnt/unionfs" ]];then fusermount -uz /mnt/unionfs && mkdir -p /mnt/unionfs;fi
if [[ -f "/config/scripts/union-mount.sh" ]];then
   bash /config/scripts/union-mount.sh
fi
sleep 5
UFSPATH=$(cat /tmp/rclone-mount.file)
rm -rf /tmp/mergerfs_mount_file && touch /tmp/mergerfs_mount_file
echo -e "defaults,nonempty,cache.symlinks=true,cache.files=auto-full,cache.open=259200,cache.statfs=259200,cache.attr=259200,cache.entry=259200,cache.negative_entry=259200,category.create=epff,minfreespace=0,allow_other,dropcacheonclose=true,security_capability=false,xattr=nosys,statfs_ignore=ro,use_ino,hard_remove,async_read=true,umask=002,noatime,security_capability=false,xattr=nosys,statfs_ignore=nc,statfs=full,threads=100,cache.writeback=true,posix_acl=false,symlinkify=true" >> /tmp/mergerfs_mount_file
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
   sleep 5
else
   startupdocker
fi

MERGERFS_PID=$(pgrep mergerfs)

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