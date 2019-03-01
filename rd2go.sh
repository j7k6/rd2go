#!/bin/bash
#
# Ramdisk-to-Go 
# https://github.com/j7k6/rd2go

set -o errexit
set -o pipefail

ramdisk_action="${1}"
ramdisk_name="${2}"
ramdisk_size="${3}"
ramdisk_mountpoint="${ramdisk_name}"

if [[ "$(uname)" = "Linux" && "${EUID}" -ne 0 ]]; then
  echo "Error: Please run as root."
  exit 1
fi

create_ramdisk () {
  if [[ -z "${ramdisk_name}" ]]; then
    echo "Error: Ramdisk name argument is missing."
    usage
    exit 1
  fi

  if [[ -z "${ramdisk_size}" ]]; then
    echo "Error: Ramdisk size argument is missing."
    usage
    exit 1
  fi

  if [[ "$(mount | grep $ramdisk_mountpoint)" != "" ]]; then
    echo "Ramdisk '${ramdisk_name}' already mounted! Doing nothing..."
    exit 0
  fi

  mkdir -p ${ramdisk_mountpoint}
  umount ${ramdisk_mountpoint} >/dev/null 2>&1 || true

  case "$(uname)" in
    Darwin)
      ramdisk_sectors=$(($ramdisk_size*1024*1024/512))
      ramdisk_dev="/dev/$(diskutil erasevolume HFS+ '${ramdisk_name}' $(hdid -nomount ram://${ramdisk_sectors}) | awk '/Started erase on/ {print $4}')"

      diskutil unmountDisk ${ramdisk_dev} >/dev/null 2>&1 || true
      mount -t hfs -o noatime,noowners ${ramdisk_dev} ${ramdisk_mountpoint} >/dev/null 2>&1
      ;;
    Linux)
      mount -t tmpfs -o size=${ramdisk_size}m,noatime,gid=$(id -g),uid=$(id -u) tmpfs ${ramdisk_mountpoint} >/dev/null 2>&1
      ;;
  esac


  if [[ "$?" -ne 0 ]]; then
    echo "Error: Ramdisk not created."
  else
    echo "Ramdisk '${ramdisk_name}' created successfully!"
    exit 0
  fi
}

destroy_ramdisk () {
  if [[ -z "${ramdisk_name}" ]]; then
    echo "Error: Ramdisk name argument is missing."
    usage
    exit 1
  fi

  umount ${ramdisk_mountpoint} >/dev/null 2>&1 || true

  if [[ "$(uname)" == "Darwin" ]]; then
    ramdisk_dev=$(mount | awk -v var="${ramdisk_mountpoint}" '$3 == var { print $1 }')

    if [[ "${ramdisk_dev}" = "" ]]; then
      echo "Ramdisk '${ramdisk_name}' doesn't exist! Doing nothing..."
      exit 0
    else
      diskutil eject ${ramdisk_dev} >/dev/null 2>&1 || true
    fi
  fi

  echo "Ramdisk '${ramdisk_name}' destroyed successfully!"
  exit 0
}

usage () {
  cat << EOF

usage: ./rd2go.sh <action> <name> [<size>]

  <action>: create|destroy|help
  <name>: mountpoint name
  <size>: ramdisk size in megabytes

EOF
}

case "${ramdisk_action}" in
  create) create_ramdisk ;;
  destroy) destroy_ramdisk ;;
  help) usage ;;
  *)
    usage
    exit 1
esac
