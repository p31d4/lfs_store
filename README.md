# Introduction

This project aims to provide an automatic way to build the LFS (Linux From Scratch) project. The main idea here isn't to provide all LFS versions that ever existed, but at least one version for each Linux Kernel main stream, so I can better understand how the Linux Kernel evolved with time.

I know there are easier ways to do that, but I also did this for learning puposes, and trust me, you really can learn A LOT with the LFS Book. So I would strongly recommend that you take your time and read the whole thing.

Be aware that this is a toy project, the scripts available here were written in my free time as a hobby activity, which means they shouldn't to be used in production. Besides that, even if I had performed a lot of tests, they still can severely damage your devices, so use them carefully and at your own risk. I'm not responsible for any misuse or damage caused by those scripts.

# How to Build

I'm assuming that your workspace, where you clone this repo, is stored in the env variable GIT_REPOS_DIR. I'm also assuming that your output directory is /mnt/lfs_12_2 (the default), but you can change it.

## Easiest way

Theoretically, running the command below should deliver you a whole functional LFS image called lfs_device.img (the default name) after a few hours (or days), and this will be placed on the folder /mnt/lfs_12_2 (the default output path and default LFS version), however I don't trust blindly those packages links and it is quite possible that some of those links won't work. I mean, last time I tried that it worked, but you never know.

```
sudo su
cd ${GIT_REPOS_DIR}/lfs_store
bash ./build_lfs.sh
```

## Safest Way

I prefer to download all the required packages first and build the LFS image after that. It ensures that a broken link won't make you waste your time. You can do that with the follwing commands and for the building part you even don't need an internet connection (assuming you environment is prepared according to the version_check.sh script)

```
sudo su
cd ${GIT_REPOS_DIR}/lfs_store
bash ./build_lfs.sh --no-dev-creation --no-mount-partitions --no-copy-pkgs --no-crosschain --no-lfs-system
bash ./build_lfs.sh --no-downloads
```

## Student Way

If you are reading through the LFS Book, you can execute the below commands to follow along. It will allow you to digest and better understand each section.

1. Donwload source packages
```
sudo su
cd ${GIT_REPOS_DIR}/lfs_store
bash ./build_lfs.sh --no-dev-creation --no-mount-partitions --no-copy-pkgs --no-crosschain --no-lfs-system
```

2. Create a new device and the required partitions
```
bash ./build_lfs.sh --no-downloads --no-mount-partitions --no-copy-pkgs --no-crosschain --no-lfs-system
```

3. Mount the required partitions
```
bash ./build_lfs.sh --no-downloads --no-dev-creation --no-copy-pkgs --no-crosschain --no-lfs-system --dev /mnt/lfs_12_2/lfs_device.img
```

4. Copy the source packages to the appropriate partition.
```
bash ./build_lfs.sh --no-downloads --no-dev-creation --no-mount-partitions --no-crosschain --no-lfs-system
```

5. Build the required Cross Toolchain
```
bash ./build_lfs.sh --no-downloads --no-dev-creation --no-mount-partitions --no-copy-pkgs --no-lfs-system

```

6. Build the LFS System
```
bash ./build_lfs.sh --no-downloads --no-mount-partitions --no-dev-creation --no-copy-pkgs --no-crosschain --dev /mnt/lfs_12_2/lfs_device.img
```

## Hacker Way

If you really want to understand the scripts you are executing and read the LFS Book at the same time, you call directly call the scripts inside each chapter.  
For example, to prepare the chroot environment, you would do the following
```
sudo su
cd ${GIT_REPOS_DIR}/lfs_store
export LFS=/mnt/lfs
bash ./lfs_12_2/chapter_7/prepare_chroot.sh
```

## Mesuring Time

The LFS Book provides a measurement unit called SBU to help estimating how long the building process will take.
A script called measure_SBU.sh is provided in the utils folder to help you measure that unit on your system.

# How to Start Over

Before build the LFS System itself, you can use the following commands to backup your Cross Toolchain environment.
```
cd /mnt/lfs_12_2
tar -cJf lfs_crosschain.tar.xz lfs_device.img

```

If something goes wrong and you have to turn your machine off. It's then possible to start over with the following commands.
```
sudo su
cd /mnt/lfs_12_2
tar -xvf lfs_crosschain.tar.xz
cd ${GIT_REPOS_DIR}/lfs_store
bash ./build_lfs.sh --no-downloads --no-dev-creation --no-copy-pkgs --no-crosschain --no-lfs-system --dev /mnt/lfs_12_2/lfs_device.img
bash lfs_12_2/chapter_7/prepare_chroot.sh
rm /mnt/lfs/sources/build_lfs.log

```

# How to Debug

If you want just prepare and enter the chroot environment to do some debugging or play around, the following commands would help.
```
sudo su
export LFS=/mnt/lfs
cd ${GIT_REPOS_DIR}/lfs_store
bash lfs_12_2/chapter_2/mount_partitions.sh /mnt/lfs_12_2/lfs_device.img 
bash lfs_12_2/chapter_7/prepare_chroot.sh 
source utils/utils.sh 
enter_chroot
```

# How to run

You can emulate your brand new LFS using Qemu or copy it to a external USB device for example, and boot directly on it.  
There is an script called emulate_lfs.sh in the utils folder which can be used, that script will work out of the box if you used the default paths.

# Future Work

This is the first version of this project and there are still a lot to do.
