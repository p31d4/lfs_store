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
    echo "    usage: $1 <device>        - path to device where the LFS system will be stored"
    exit 1
}

if [ -z "$1" ]
then
    usage $0
fi

# TODO: get these as arguments
SAFETY_CHECKS="NO"
FILL_WITH_ZEROS="NO"

if [ $SAFETY_CHECKS == "YES" ]; then
echo -e "\nBe careful, this script may destroy your device, I'm not responsible for any trouble ;)"
read -p "Proceed? (y/n) " -e PROCEED && [[ ${PROCEED} == [yY] ]] || exit 1
fi

#------------------------------------------------------------------------------
# PARTITIONS - CHAPTER 2.4
#------------------------------------------------------------------------------

DEV=$1

# BIOS/MBR
parted -s "$1" mklabel msdos
parted -s "$1" mkpart primary 1MiB 201MiB     # boot partition

# EFI size following this recommendation: https://www.rodsbooks.com/linux-uefi/ 
parted -s "$1" mkpart primary 201MiB 751MiB   # EFI partition
parted -s "$1" mkpart primary 751MiB 4847MiB  # swap partition
parted -s "$1" mkpart primary 4847MiB 100%    # root partition

# check if it's a physical or loop device
echo $1 | grep -E "^\/dev\/sd[a-z].*$"
if [ $? != 0 ]; then
    # find the first loop device available
    DEV="$(losetup -f)p"
    losetup -P ${DEV::-1} $1
fi

if [ $FILL_WITH_ZEROS == "YES" ]; then
echo "[INFO] Formating boot partition..."
dd if=/dev/zero of=${DEV}1 bs=20M status=progress count=10 && sync
fi
mkfs.ext2 "${DEV}1"

#echo "Formating EFI partition..."
#dd if=/dev/zero of=${DEV}1 bs=10M status=progress count=50 && sync

grep -E "^\/dev\/sd[a-z].*$" $1
if [ $? == 0 ]; then
    parted -s ${DEV} set 2 boot on
else
    parted -s ${DEV::-1} set 2 boot on
fi
echo "[INFO] Creating FAT32 file system..."
mkfs.fat -F32 "${DEV}2"

if [ $FILL_WITH_ZEROS == "YES" ]; then
# fill swap partition with zeros
read -p "Fill swap partition with zeros (this can take some time)? (y/n) " -e ZERO && [[ ${ZERO} == [yY] ]] && \
	shred -v -f -n1 --random-source=/dev/zero "${DEV}3"
fi
mkswap "${DEV}3"
swapon "${DEV}3"

if [ $FILL_WITH_ZEROS == "YES" ]; then
# fill root partition with zeros
read -p "Fill root partition with zeros (this can take some time)? (y/n) " -e ZERO && [[ ${ZERO} == [yY] ]] && \
	shred -v -f -n1 --random-source=/dev/zero "${DEV}4"
fi
echo "[INFO] Creating EXT4 file system..."
mkfs.ext4 "${DEV}4"

#losetup -d ${DEV::-1}

#fdisk -l $1
#tune2fs -l $1
blkid | grep -i "^/dev/loop"

echo "[INFO] Device partitioned!"
