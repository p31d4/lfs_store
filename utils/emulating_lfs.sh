#!/bin/bash

qemu-system-x86_64 -m 1024M \
    -hda /mnt/lfs_12_2/lfs_device.img \
    -kernel /mnt/lfs/boot/vmlinuz-6.10-lfs-12.2 \
    -append "root=/dev/sda4 console=ttyS0" \
    -nographic -smp cores=2
