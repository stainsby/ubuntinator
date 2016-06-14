#!/bin/bash

BTITLE="Ubuntinator"
BUILD_DIR=`mktemp -d`
echo "building in $BUILD_DIR ..."
BUILD_LOG_DIR="$BUILD_DIR/log"
BUILD_LOG_FILE="$BUILD_LOG_DIR/build_log.txt"
BUILD_ROOTFS="$BUILD_DIR/rootfs"

mkdir -p "$BUILD_LOG_DIR"

function blog() {
  echo $1 >> "$BUILD_LOG_FILE"
  echo $1
}


function cleanup() {
  blog "doing cleanups"
  MANUALLY_CLEAN=""
  [[ ! -z "$CHROOT_LOG_MOUNTED" ]]  && ( umount "$BUILD_ROOTFS/$CHROOT_APP_DIR/log" || ( blog "failed to unmount bound mount points in the chroot"  && MANUALLY_CLEAN="1" ) )
  [[ ! -z "$CHROOT_DEV_MOUNTED" ]]  && ( umount "$BUILD_ROOTFS/dev"                 || ( blog "failed to unmount bound mount points in the chroot" && MANUALLY_CLEAN="1" ) )
  [[ ! -z "$CHROOT_PROC_MOUNTED" ]] && ( umount "$BUILD_ROOTFS/proc"                || ( blog "failed to unmount bound mount points in the chroot" && MANUALLY_CLEAN="1" ) )
  [[ ! -z "$ROOTFS_MOUNTED" ]]      && ( umount "$BUILD_ROOTFS"                     || ( blog "failed to unmount root file system" && MANUALLY_CLEAN="1" ) )
  [[ -z "$MANUALLY_CLEAN" ]] && rm -rf "$BUILD_DIR"
  [[ ! -z "$MANUALLY_CLEAN" ]] && echo "you need to manually clean $BUILD_DIR .. ENSURE that you unmount $BUILD_ROOTFS/dev and/or  "$BUILD_ROOTFS/proc"  in the chroot FIRST or you may crash your host"
  echo "exiting"
}
trap cleanup EXIT


function abort() {
  REASON="$1"
  [[ -z "$REASON" ]] && REASON="by user request"
  echo
  blog "Aborted: $REASON"
  echo
  exit 1
}




# CREATE ROOT FILESYSTEM


INSTALL_DEV=`dialog --stdout --backtitle "$BTITLE" --title "Select install location" --inputbox "This script will install Ubuntu into a partition, (re-)label the partition, and, optionally, install a bootloader. You need to provide an empy partition with a EXT filesystem on it such as EXT4.\n\nEnter the device file (eg. /dev/sdd1) to install to:" 20 60` || abort
blog "install device '$INSTALL_DEV' selected"

mkdir -p "$BUILD_ROOTFS"
mount "$INSTALL_DEV" "$BUILD_ROOTFS" || abort "unable to mount $INSTALL_DEV on $BUILD_ROOTFS"
ROOTFS_MOUNTED="1"


[[ ! -z `ls -A "$BUILD_ROOTFS" | grep -v 'lost+found'` ]] && {
  blog "aborting because partition is not empty"
  abort "partition not empty"
}

e2label "$INSTALL_DEV" UBUROOT || abort "failed to label partition"

RELEASE_PATH=`dialog --stdout --backtitle "$BTITLE" --title "Select Release" --no-tags --menu "Select the Ubuntu Base release you want to install." 40 80 20 --file release_tags.txt` || abort
RELEASE=`echo $RELEASE_PATH | cut -d '/' -f 1`
blog "release '$RELEASE' selected"

ARCH=`dialog --stdout --backtitle "$BTITLE" --title "Select Architecture" --menu "Select the Ubuntu Base release you want to install." 40 80 20 --file arch_tags.txt` || abort
blog "architecture '$ARCH' selected"

# eg. http://cdimage.ubuntu.com/ubuntu-base/releases/xenial/release/ubuntu-base-16.04-core-amd64.tar.gz
ROOTFS_URL="http://cdimage.ubuntu.com/ubuntu-base/releases/$RELEASE_PATH-$ARCH.tar.gz"
blog "dowloading root filesystem tarball from $ROOTFS_URL ..."
ROOTFS_FNAME="$RELEASE-$ARCH.tar.gz"
# TOOD: curl -o "$BUILD_DIR/$ROOTFS_FNAME" "$ROOTFS_URL" || {
#   blog "failed to download root file system tarball"
# }
ROOTFS_DOWNLOAD="/tmp/ubuntinator-$ROOTFS_FNAME" 
wget -c -O "$ROOTFS_DOWNLOAD" "$ROOTFS_URL" && cp -a "$ROOTFS_DOWNLOAD" "$BUILD_DIR/$ROOTFS_FNAME" || {
  blog "failed to download root file system tarball"
}

( cd "$BUILD_ROOTFS" && pwd && tar xzf "$BUILD_DIR/$ROOTFS_FNAME" ) || abort "failed to extract root filesystem into $BUILD_ROOTFS"


# PREPARE CHROOT


CHROOT_APP_DIR="/usr/local/ubuntinator"
mkdir -p "$BUILD_ROOTFS/$CHROOT_APP_DIR/log"

blog "adding bound mounts to chroot"
mount --bind "$BUILD_LOG_DIR" "$BUILD_ROOTFS/$CHROOT_APP_DIR/log" || abort "failed to bind /dev into root fielsystem"
CHROOT_LOG_MOUNTED="1"
mount --bind /dev "$BUILD_ROOTFS/dev" || abort "failed to bind /dev into root fielsystem"
CHROOT_DEV_MOUNTED="1"
mount --bind /proc "$BUILD_ROOTFS/proc" || abort "failed to bind /proc into root fielsystem"
CHROOT_PROC_MOUNTED="1"

# temporary networking
[[ -e /etc/resolv.conf ]] && cp /etc/resolv.conf "$BUILD_ROOTFS/etc/resolv.conf" || blog "couldn't copy resolv.conf: chroot networking may fail"

# copy chroot script
cp ./phase2.sh  ./phase3.sh ./linux_image_tags.txt "$BUILD_ROOTFS/$CHROOT_APP_DIR" || abort "failed to copy required files to chroot"
CHROOT_CMD="$CHROOT_APP_DIR/phase2.sh"
blog "executing chroot with command $CHROOT_CMD"


# DO CHROOT .. AND ON TO PHASE 2


chroot "$BUILD_ROOTFS" "$CHROOT_APP_DIR/phase2.sh" "" abort "chroot failed"
