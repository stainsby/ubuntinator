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


blog "getting network parameters via DHCP"
dhclient && sleep 3 || abort "failed to get network parameters"

blog "updating package database"
apt-get update || abort "failed to update package database"

blog "installing dialog packages"
apt-get -y install dialog whiptail || abort "failed to install dialog packages"

apt-get -y install console-setup || abort "failed to install console package"

blog "installing language package"
apt-get -y install language-pack-en || abort "failed to install language package"

blog "adding some basic networking packages"
apt-get -y install isc-dhcp-client netbase || abort "failed to install basic networking packages"

blog "adding useful extra packages"
apt-get -y install language-pack-en pciutils usbutils apt-utils bash-completion rsyslog cron util-linux \
  rsync openssh-server openssh-client net-tools iputils-ping sudo less nano \
  psmisc e2fsprogs htop man curl wget || abort "failed to install extra packages"

blog "configuring network"
NET_DEVICES=`ip - o link | cut -d " " -f 2 | cut -d ":" -f1 | grep -vP "^(lo)?$"`
NET_DEVICE=`dialog --stdout --backtitle "$BTITLE" --title "Select network device" --no-items --menu "Select the network device you would like to use with DHCP." 40 80 20 $NET_DEVICES`
[[ -n "$NET_DEVICE" ]] && {
  echo -e "\nauto lo\niface lo inet loopback\n" >> /etc/network/interfaces
  echo -e "\nauto $NET_DEVICE\niface $NET_DEVICE inet dhcp\n" >> /etc/network/interfaces
}

blog "updating GRUB one last time"
update-grub2

blog "cleaning up"
apt-get -y autoremove && apt-get clean

blog "installation complete - you should REBOOT now"
