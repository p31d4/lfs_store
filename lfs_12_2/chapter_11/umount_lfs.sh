#!/bin/bash

if [ x"${LFS}" == "x" ]; then
    echo "LFS variable is not set"
    exit 1
fi

#------------------------------------------------------------------------------
# CHAPTER 11
#------------------------------------------------------------------------------

ROOT_DEV=$(mount | grep "/mnt/lfs type ext4" | cut -d" " -f1)

umount -v $LFS/dev/pts
mountpoint -q $LFS/dev/shm && umount -v $LFS/dev/shm
umount -v $LFS/dev
umount -v $LFS/run
umount -v $LFS/proc
umount -v $LFS/sys

umount -v $LFS/boot/efi
umount -v $LFS/boot
#umount -v $LFS/home
umount -v $LFS

swapoff "${ROOT_DEV::-1}3"

echo "[INFO] FINISHED"
