#!/bin/bash

if [ x"$LFS" == "x" ]; then
    echo "LFS variable is not set! Exiting..."
    exit 1
fi

#------------------------------------------------------------------------------
# CHAPTER 7
#------------------------------------------------------------------------------

#findmnt

chown --from lfs -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
# Extra
chown --from lfs -R root:root $LFS/sources

case $(uname -m) in
    x86_64) chown --from lfs -R root:root $LFS/lib64 ;;
esac

#------------------------------------------------------------------------------
# Virtual Kernel File Systems
#------------------------------------------------------------------------------

mkdir -pv $LFS/{dev,proc,sys,run}

#devtmpfs ??? command not found in arch
mount -v --bind /dev $LFS/dev

# 7.3.2
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

#pt_chown ???

if [ -h $LFS/dev/shm ]; then
    install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
    mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi

# Extra
mkdir -pv $LFS/{root,tmp,home}

echo "[INFO] chroot environment prepared!"
