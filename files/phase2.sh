#!/bin/bash

# must match value from phase1
CHROOT_APP_DIR="/usr/local/ubuntinator"

BTITLE="Ubuntinator"
BUILD_LOG_DIR="$CHROOT_APP_DIR/log"
BUILD_LOG_FILE="$BUILD_LOG_DIR/build_log.txt"

function blog() {
  echo $1 >> "$BUILD_LOG_FILE"
  echo "## CHROOT: $1"
}


function abort() {
  REASON="$1"
  [[ -z "$REASON" ]] && REASON="by user request"
  echo
  blog "Aborted: $REASON"
  echo
  exit 1
}


blog "chroot running"
cd "$CHROOT_APP_DIR"
blog "updating package database from network"
apt-get update && apt-get -y install software-properties-common || abort "unable to install required initial packages (1)"
blog "adding dialog package"
add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe" && apt-get update && apt-get -y install dialog || abort "unable to install required initial packages (1)"


KERNEL_IMAGE=`dialog --stdout --backtitle "$BTITLE" --title "Select Kernel" --no-tags --menu "Select the Linux kernel you want to install." 40 80 20 --file linux_image_tags.txt` || abort
blog "kernel image '$KERNEL_IMAGE' selected"

apt-get install -y "$KERNEL_IMAGE" || abort "failed to install Linux kernel"

echo
blog "set a root password:"
passwd root || abort "failed to set a root password"
echo 'LABEL=UBUROOT / auto errors=remount-ro 0 1' >> /etc/fstab || abort "failed to add root entry to fstab"

HOST_NAME=`dialog --stdout --backtitle "$BTITLE" --title "Set a host name" --inputbox "Enter name for the new host" 20 60` || abort

echo "$HOST_NAME" > /etc/hostname || abort "failed to add hostname"
hostname "$HOST_NAME"

blog "adding some networking packages"
apt-get -y install isc-dhcp-client netbase iw wpasupplicant net-tools iputils-ping || abort "failed to install networking packages"

blog "preparing system for boot"
cp -a /etc/rc.local /etc/rc.local.UBU_BAK && \
  echo '#!/bin/sh -e' > /etc/rc.local && \
  echo "$CHROOT_APP_DIR/phase3.sh" >> /etc/rc.local

blog "Success! You should now BOOT the new system to complete the installation."
