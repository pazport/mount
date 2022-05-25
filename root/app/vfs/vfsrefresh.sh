#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# ## function source start
# shellcheck disable=SC2086
# shellcheck disable=SC2002
# shellcheck disable=SC2006
ENV="/config/env/rclone.env"
VFS_REFRESH=$(grep -e "VFS_REFRESH" "$ENV" | sed "s#.*=##")
function drivecheck() {
while true; do
  MERGERFS_PID=$(pgrep mergerfs)
  if [ ! "${MERGERFS_PID}" ]; then
      sleep 5 && continue
   else
      break
  fi
done
while true;do
SRC=/config/rc-refresh/union-rc-file.sh
if [[ -f ${SRC} ]];then
   bash ${SRC} && chmod a+x ${SRC} && chown -hR abc:abc ${SRC} && truncate -s 0 /config/logs/*.log
   break
fi
done   
}
while true; do
   if [[ ! "${VFS_REFRESH}" ]]; then
     break
   else
     drivecheck && sleep "${VFS_REFRESH}" && continue
   fi
done
#EOF'