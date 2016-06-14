#!/bin/bash

# must match value from phase1
CHROOT_APP_DIR="/usr/local/ubuntinator"

BTITLE="Ubuntinator"
BUILD_LOG_DIR="$CHROOT_APP_DIR/log"
BUILD_LOG_FILE="$BUILD_LOG_DIR/build_log.txt"


function blog() {
  echo $1 >> "$BUILD_LOG_FILE"
  echo "## UBUNTINATOR: $1"
}


function abort() {
  REASON="$1"
  [[ -z "$REASON" ]] && REASON="by user request"
  echo
  blog "Aborted: $REASON"
  echo
  exit 1
}


blog "getting network paramaters via DHCP"
dhclient && sleep 3 || abort "failed to get network paramters"

blog "finishing installation"
blog "updating installed packages"
apt-get update && apt-get -y upgrade || abort "failed to update installed packages"
  
blog "adding useful extra packages"
apt-get -y install console-setup language-pack-en dialog netbase pciutils \
  usbutils apt-utils bash-completion isc-dhcp-client rsyslog cron util-linux \
  rsync openssh-server openssh-client net-tools iputils-ping sudo less nano \
  psmisc e2fsprogs htop || abort "failed to install extra packages"

blog "updating GRUB one last time"
update-grub2

blog "cleaning up"
apt-get -y autoremove && apt-get clean

blog "restoring rc.local"
( sleep 1 ; mv /etc/rc.local.UBU_BAK  /etc/rc.local ) &

blog "installation complete - you should REBOOT now"
