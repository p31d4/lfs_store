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

usage() {
    echo "Usage:"
    echo "    $0 [options]"
    echo "Options:"
    echo "    --backup                 perform the backup of the cross toolchain before the LFS System installation"
    echo "    --dev <device>           path to device where the LFS system will be stored"
    echo "                             it can be a physical device like /dev/sdc"
    echo "                             or a loop device like lfs_device.img"
    echo '                             if this value is not provided the default is: /mnt/${LFS_VERSION}/lfs_device.img'
    echo "    -h | --help              show this message"
    echo "    --lfs-version            which LFS version shall be build. Default is lfs_12_2"
    echo "    -o | --output-dir        path to directory where the \"img\" and the backup file will be saved"
    echo "    --no-copy-pkgs           won't copy the source packages to the folder /mnt/lfs/sources"
    echo "    --no-crosschain          won't build the cross toolchain. Chapters: 4, 5, 6 and 7"
    echo "    --no-dev-creation        won't create a new device and the required partitions"
    echo "    --no-downloads           won't download the source packages"
    echo "    --no-lfs-system          won't build the LFS System"
    echo "    --no-mount-partitions    won't mount the device partitions"
    echo "    -p | --partitions        create the partitions in the device"
    echo "    -t | --test              execute all the tests for the LFS System. This will take forever"

    exit 1
}

export LFS=/mnt/lfs
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd )
DEV=
LFS_VERSION=lfs_12_2
OUTPUT_DIR=/mnt/${LFS_VERSION}
DO_PARTITIONS=
DO_BACKUP=
NO_COPY_PKGS=
NO_CROSSCHAIN=
NO_DEV_CREATION=
NO_DOWNLOADS=
NO_LFS_SYSTEM=
NO_MOUNT_PARTITIONS=
TEST_FLAG=

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -b|--backup)
      DO_BACKUP=Y
      shift
      ;;
    -d|--dev)
      DEV="$2"
      shift
      shift
      ;;
    -h|--help)
      usage
      shift
      ;;
    --lfs-version)
      LFS_VERSION="$2"
      shift
      shift
      ;;
    -o|--output-dir)
      OUTPUT_DIR="$2"
      shift
      shift
      ;;
    --no-copy-pkgs)
      NO_COPY_PKGS="Y"
      shift
      ;;
    --no-crosschain)
      NO_CROSSCHAIN="Y"
      shift
      ;;
    --no-dev-creation)
      NO_DEV_CREATION="Y"
      shift
      ;;
    --no-downloads)
      NO_DOWNLOADS="Y"
      shift
      ;;
    --no-lfs-system)
      NO_LFS_SYSTEM="Y"
      shift
      ;;
    --no-mount-partitions)
      NO_MOUNT_PARTITIONS="Y"
      shift
      ;;
    -p|--partitions)
      DO_PARTITIONS="Y"
      shift
      ;;
    -t|--test)
      TEST_FLAG="--test"
      shift
      ;;
    -*|--*)
      echo "Unknown argument $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

export LFS_VERSION=$LFS_VERSION

. ${BASE_DIR}/utils/utils.sh

# write banner
banner() {
echo "LFS: $LFS"
echo "BASE_DIR: $BASE_DIR"
echo "DEV: $DEV"
echo "LFS_VERSION: $LFS_VERSION"
echo "TEST_FLAG: $TEST_FLAG"
echo "OUTPUT_DIR: $OUTPUT_DIR"
echo "NO_COPY_PKGS: $NO_COPY_PKGS"
echo "NO_CROSSCHAIN: $NO_CROSSCHAIN"
echo "NO_DEV_CREATION: $NO_DEV_CREATION"
echo "NO_DOWNLOADS: $NO_DOWNLOADS"
echo "NO_LFS_SYSTEM: $NO_LFS_SYSTEM"
echo "NO_MOUNT_PARTITIONS: $NO_MOUNT_PARTITIONS"
echo "DO_PARTITIONS: $DO_PARTITIONS"
echo "DO_BACKUP: $DO_BACKUP"
}
banner

#------------------------------------------------------------------------------
# DOWNLOAD PACKAGES
#------------------------------------------------------------------------------

download_pkgs() {

# TODO: make this work
#bash ${BASE_DIR}/utils/get_pkgs.sh "${LFS_VERSION}"

mkdir -pv ${BASE_DIR}/${LFS_VERSION}/pkgs

# THIS IS UGLY AND UNSTABLE
wget --input-file=${BASE_DIR}/${LFS_VERSION}/chapter_3/wget-list-sysv --continue --directory-prefix=${BASE_DIR}/${LFS_VERSION}/pkgs

if [ "$(wc -l ${BASE_DIR}/${LFS_VERSION}/chapter_3/wget-list-sysv | cut -d" " -f1)" != "$(ls ${BASE_DIR}/${LFS_VERSION}/pkgs | wc -l)" ]; then
    check_missing_pkgs
    exit 1
else
    pushd ${BASE_DIR}/${LFS_VERSION}/pkgs
    md5sum -c ${BASE_DIR}/${LFS_VERSION}/chapter_3/md5sums &> /dev/null | grep "FAILED" &> /dev/null
    if [ $? == 0 ];then
        echo "[ERROR] Some package is corrupted! Run md5sum on the pkgs directory"
    fi
    popd
fi

# This will be deprecated when the git mechanism is in place
if [ ${LFS_VERSION} == "lfs_12_2" ]; then
mv ${BASE_DIR}/${LFS_VERSION}/pkgs/tcl8.6.14-src.tar.gz ${BASE_DIR}/${LFS_VERSION}/pkgs/tcl-8.6.14.tar.gz
mv ${BASE_DIR}/${LFS_VERSION}/pkgs/expect5.45.4.tar.gz ${BASE_DIR}/${LFS_VERSION}/pkgs/expect-5.45.4.tar.gz
mv ${BASE_DIR}/${LFS_VERSION}/pkgs/systemd-man-pages-256.4.tar.xz ${BASE_DIR}/${LFS_VERSION}/pkgs/Systemd-man-pages-256.4.tar.xz
fi

sanitize_pkgs
}

#------------------------------------------------------------------------------
# DEVICE CREATION AND PARTITIONING
#------------------------------------------------------------------------------

exec_dev_creation() {

local out_dir_size

if [ x"${DEV}" == "x" ]; then

    create_device "${OUTPUT_DIR}"
    DEV="${OUTPUT_DIR}/lfs_device.img"
    DO_PARTITIONS=Y

    echo "[INFO] Device $DEV created!"
fi
}

exec_dev_partitioning() {

if [ "${DO_PARTITIONS}" == "Y" ]; then
    if [ ! -e ${DEV} ];then
        echo "[ERROR] device ${DEV} does not exist!"
        exit 1
    fi
    bash ${BASE_DIR}/utils/create_partitions.sh "${DEV}"
fi
}

#------------------------------------------------------------------------------
# CHAPTER 2
#------------------------------------------------------------------------------

exec_system_check() {

bash ${BASE_DIR}/${LFS_VERSION}/chapter_2/version-check.sh | grep -i "error"

if [ $? == 0 ]
then
    echo "[ERROR] version-check.sh returned an error, please check your environment!"
    exit 1
fi
}

exec_mount_partitions() {

bash ${BASE_DIR}/${LFS_VERSION}/chapter_2/mount_partitions.sh ${DEV}
}

#------------------------------------------------------------------------------
# CHAPTER 3
#------------------------------------------------------------------------------

exec_chapter_3() {

bash ${BASE_DIR}/${LFS_VERSION}/chapter_3/get_sources.sh
}

#------------------------------------------------------------------------------
# CHAPTER 4
#------------------------------------------------------------------------------

exec_chapter_4() {

bash ${BASE_DIR}/${LFS_VERSION}/chapter_4/add_lfs_user.sh
}

#------------------------------------------------------------------------------
# CHAPTER 5
#------------------------------------------------------------------------------

exec_chapter_5() {

get_utils "/home/lfs"

cp -v ${BASE_DIR}/${LFS_VERSION}/chapter_5/*.sh /home/lfs

sudo -u lfs bash << EOF
bash ~/exec_lfs_env.sh "cross_toolchain.sh"
EOF
}

#------------------------------------------------------------------------------
# CHAPTER 6
#------------------------------------------------------------------------------

exec_chapter_6() {

# just in case
get_utils "/home/lfs"
cp -v ${BASE_DIR}/${LFS_VERSION}/chapter_5/exec_lfs_env.sh /home/lfs

cp -v ${BASE_DIR}/${LFS_VERSION}/chapter_6/*.sh /home/lfs

sudo -u lfs bash << EOF
bash -x ~/exec_lfs_env.sh "cross_toolchain_temp_tools.sh"
EOF
}

#------------------------------------------------------------------------------
# CHAPTER 7
#------------------------------------------------------------------------------

exec_chapter_7() {

bash ${BASE_DIR}/${LFS_VERSION}/chapter_7/prepare_chroot.sh

get_utils "$LFS/root"

cp -v ${BASE_DIR}/${LFS_VERSION}/chapter_7/*.chroot $LFS/root

exec_chroot "chroot_env.chroot"
exec_chroot "chroot_additional_temp_tools.chroot"

rm -v $LFS/root/*.chroot
}

#------------------------------------------------------------------------------
# CHAPTER 8
#------------------------------------------------------------------------------

exec_chapter_8() {

get_utils "$LFS/root"

cp -v ${BASE_DIR}/${LFS_VERSION}/chapter_8/*.chroot $LFS/root

# TODO: check if chroot env is prepared
exec_chroot "basic_system_software.chroot" $TEST_FLAG
}

#------------------------------------------------------------------------------
# CHAPTER 9
#------------------------------------------------------------------------------

exec_chapter_9() {

get_utils "$LFS/root"

cp -v ${BASE_DIR}/${LFS_VERSION}/chapter_9/*.chroot $LFS/root

exec_chroot "system_config.chroot"
}

#------------------------------------------------------------------------------
# CHAPTER 10
#------------------------------------------------------------------------------

exec_chapter_10() {

# this is required for the grub install command
DEV_GRUB=

# check if it's a physical or loop device
if [ $(get_dev_type $1) == "loop" ]; then
    DEV_GRUB="$(losetup --list --noheadings | grep -i "${1##*/}" | cut -d" " -f1)"
else
    DEV_GRUB="${DEV}"
fi

get_utils "$LFS/root"

cp -v ${BASE_DIR}/${LFS_VERSION}/chapter_10/*.chroot $LFS/root

exec_chroot "making_lfs_bootable.chroot" $DEV_GRUB
}

#------------------------------------------------------------------------------
# CHAPTER 11
#------------------------------------------------------------------------------

exec_chapter_11() {

cp -v ${BASE_DIR}/${LFS_VERSION}/chapter_11/*.chroot $LFS/root

exec_chroot "the_end.chroot"
}

#******************************************************************************

#------------------------------------------------------------------------------
# PREPARATION
#------------------------------------------------------------------------------

mkdir -pv $OUTPUT_DIR
exec_system_check

if [ "${NO_DOWNLOADS}" != "Y" ]; then
download_pkgs
fi

if [ "${NO_DEV_CREATION}" != "Y" ]; then
exec_dev_creation
exec_dev_partitioning
fi

if [ "${NO_MOUNT_PARTITIONS}" != "Y" ]; then
exec_mount_partitions
fi

if [ "${NO_COPY_PKGS}" != "Y" ]; then
exec_chapter_3
fi

if [ "${NO_CROSSCHAIN}" != "Y" ]; then
exec_chapter_4
exec_chapter_5
check_error_chapter "5"
exec_chapter_6
check_error_chapter "6"
exec_chapter_7
check_error_chapter "7"
echo "lala"
fi

if [ "${DO_BACKUP}" == "Y" ]; then

    mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
    umount $LFS/dev/pts
    umount $LFS/{sys,proc,run,dev}

    if [ $(get_dev_type ${DEV}) == "dev" ]; then
        create_backup "dev" "${OUTPUT_DIR}"
    else
        create_backup "loop" "${OUTPUT_DIR}"
    fi

    # mount again
    bash ${BASE_DIR}/${LFS_VERSION}/chapter_7/prepare_chroot.sh
fi

#------------------------------------------------------------------------------
# SYSTEM
#------------------------------------------------------------------------------

if [ "${NO_LFS_SYSTEM}" != "Y" ]; then
exec_chapter_8
check_error_chapter "8"
exec_chapter_9
check_error_chapter "9"
exec_chapter_10 ${DEV}
check_error_chapter "10"
exec_chapter_11
check_error_chapter "11"
fi

#if [ "${NO_MOUNT_PARTITIONS}" != "Y" ]; then
#bash ${BASE_DIR}/${LFS_VERSION}/chapter_11/umount_lfs.sh
#fi

echo -e "\n[INFO] THAT WAS A LOOOOOT OF WORK!\n"
echo "[INFO] DONE BY p31d4"
