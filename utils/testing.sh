#!/bin/bash

#------------------------------------------------------------------------------
# PROLOGUE
#------------------------------------------------------------------------------

# check if the script is being running with root privileges
if [ "$EUID" -ne 0 ]
then
    echo "Please run as root"
    exit 1
fi

LFS_STORE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd )/..


# Mesure SBU
#bash ${LFS_STORE_DIR}/utils/measure_SBU.sh

#1. Donwload source packages
time bash ./build_lfs.sh --no-dev-creation --no-mount-partitions --no-copy-pkgs --no-crosschain --no-lfs-system
grep -i error ${LFS_STORE_DIR}/download_pkgs.log && rm ${LFS_STORE_DIR}/download_pkgs.log && exit 1

#2. Create a new device and the required partitions
time bash ./build_lfs.sh --no-downloads --no-mount-partitions --no-copy-pkgs --no-crosschain --no-lfs-system

#3. Mount the required partitions
time bash ./build_lfs.sh --no-downloads --no-copy-pkgs --no-crosschain --no-lfs-system --dev /mnt/lfs_12_2/lfs_device.img

#4. Copy the source packages to the appropriate partition.
time bash ./build_lfs.sh --no-downloads --no-mount-partitions --no-crosschain --no-lfs-system --dev /mnt/lfs_12_2/lfs_device.img

#5. Build the required Cross Toolchain
time bash ./build_lfs.sh --no-downloads --no-mount-partitions --no-copy-pkgs --no-lfs-system --dev /mnt/lfs_12_2/lfs_device.img --backup

#6. Build the LFS System
time bash ./build_lfs.sh --no-downloads --no-mount-partitions --no-copy-pkgs --no-crosschain --dev /mnt/lfs_12_2/lfs_device.img

# 223min 
