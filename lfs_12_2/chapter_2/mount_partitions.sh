#!/bin/bash

#------------------------------------------------------------------------------
# user stuff
#------------------------------------------------------------------------------
# check if the script is being running with root privileges
if [ "$EUID" -ne 0 ]
then
    echo "Please run as root"
    exit 1
fi

usage() {
    echo "    usage: $1 <device>        - device where the LFS system will be stored"
    exit 1
}

if [ -z "$1" ]
then
    usage $0
fi

if [ x"${LFS}" == "x" ]; then
    echo "LFS variable is not set"
    exit 1
fi

# TODO: use this as an input parameter to build more than 1 LFS at the same time
ROOT_PT_NUM=4

#------------------------------------------------------------------------------
# CHAPTER 2: 2.6, 2.7
#------------------------------------------------------------------------------

DEV=

# Verify if the loopback device needs to be attached
# for the case where something goes wrong and the machine needs a reboot
# the create_partitions.sh script won't be suitable anymore
# and the loopack device needs to be attached again

# check if it's a physical or loop device
echo "$1" | grep -E "^\/dev\/sd[a-z]?$"
if [ $? != 0 ]; then

    losetup -a | grep -i "${1##*/}"
    if [ $? != 0 ]; then
        echo "[INFO] Mounting ${1##*/} as a loopback device!"
        losetup -P "$(losetup -f)" $1
    fi
    DEV="$(losetup --list --noheadings | grep -i "${1##*/}" | cut -d" " -f1)p"
else
    DEV=$1
fi

mkdir -pv $LFS
mount -v -t ext4 "${DEV}${ROOT_PT_NUM}" $LFS

mkdir -pv $LFS/{boot,home,root}
mount -v -t ext2 "${DEV}1" $LFS/boot
# TODO: when UEFI is in place
##mount -v -t ext4 /dev/sda5 $LFS/home

mkdir -pv $LFS/boot/efi
mount -v -t vfat "${DEV}2" $LFS/boot/efi

swapon "${DEV}3"

mount | grep -i "^/dev/loop"

echo "[INFO] Partitions mounted!"
