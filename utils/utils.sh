#!/bin/bash

get_utils() {

    if [ x"${BASE_DIR}" == "x" ] ; then
        echo "[ERROR] BASE_DIR is not set!"
	exit 1
    fi

    cp -v ${BASE_DIR}/utils/utils.sh $1
}

print_80x() {
    for idx in {1..80}; do
        echo -n "$1" | tee -a $LFS/sources/build_lfs.log
    done
    echo "" | tee -a $LFS/sources/build_lfs.log

}

extr_enter_pkg() {

    # LFS shall be "/mnt/lfs" fhor the host environment
    # and shall be unset for the chroot environment 

    local dir_name
    local pkg_name

    cd $LFS/sources
    pkg_name=$(find $LFS/sources -name "$1-*.tar.*" -type f)
    print_80x "-"
    echo "[INFO] Extracting ${pkg_name} ..." | tee -a $LFS/sources/build_lfs.log
    print_80x "-"
    tar -xf ${pkg_name}
    if [ $? != 0 ]; then
        echo "[ERROR] tar uncompression from $1 returned an error!" | \
		tee -a $LFS/sources/build_lfs.log
        exit 1
    fi

    dir_name=$(find $LFS/sources -mindepth 1 -maxdepth 1 -name "$1*" \
	    -type d -printf '%f')
    #if [ ! -d "${1%.*.*}" ]; then
    if [ x"${dir_name}" == "x" ]; then
        echo "[ERROR] No directory found for $1!" | \
		tee -a $LFS/sources/build_lfs.log
	exit 1
    fi
    cd "${dir_name}"
}

rm_pkg() {

    # LFS shall be "/mnt/lfs" fhor the host environment
    # and shall be unset for the chroot environment 

    echo "[INFO] Removing $1 directory ..." | tee -a $LFS/sources/build_lfs.log
    print_80x "-"
    cd $LFS/sources
    find $LFS/sources -mindepth 1 -maxdepth 1 -name "$1*" -type d \
	    -exec rm -r &> /dev/null {} \;
}

check_missing_pkgs() {

    if [ x"${BASE_DIR}" == "x" ] || [ x"${LFS_VERSION}" == "x" ] ; then
        echo "[ERROR] BASE_DIR or LFS_VERSION not set!"
	return
    fi

    for pkg in $(cat ${BASE_DIR}/${LFS_VERSION}/chapter_3/wget-list-sysv); do
        if [ ! -e "${BASE_DIR}/${LFS_VERSION}/pkgs/${pkg##*/}" ];then
            echo "[ERROR] ${pkg##*/} was not downloaded" | tee -a $LFS/download_pkgs.log
        fi
    done
}

sanitize_pkgs() {
    if [ x"${BASE_DIR}" == "x" ] || [ x"${LFS_VERSION}" == "x" ] ; then
        echo "[ERROR] BASE_DIR or LFS_VERSION not set!"
	return
    fi

    sed -e 's/[[:space:]]*#.*// ; /^[[:space:]]*$/d' "${BASE_DIR}/${LFS_VERSION}/versions" |
    while read pkg_alias pkg_tag pkg_version gen_cmd; do
        if [ 1 != $(find ${BASE_DIR}/${LFS_VERSION}/pkgs -iname "${pkg_alias}-*.tar.*" -type f | wc -l) ]
        then
            # Some packages will hit twice because one of them is the html package
	    # which will not be installed alone
            ls ${BASE_DIR}/${LFS_VERSION}/pkgs | grep -i ${pkg_alias} | grep -i html &> /dev/null || \
            echo "[ERROR] Pkg ${pkg_alias} will hit more than one tarball on 'extr_enter_pkg', please check." && \
            exit 1
        fi
    done

}

create_device() {

    if [ -z "$1" ]; then
        echo "[ERROR] Please provide the output path"
        exit 1
    elif [ ! -d "$1" ]
    then
        echo "[ERROR] Please provide a valid output path"
        exit 1
    fi

    # check if there is enough space in the output dir - at least 17GiB
    out_dir_size=$(df -B1 ${OUTPUT_DIR} | grep -v "Filesystem" | tr -s " " | cut -d" " -f 4)
    if [ "18253611008" -gt $out_dir_size ]; then
        echo "[ERROR] Not enough space in the output dir!"
        exit 1
    fi

    # create a 32GiB device
    echo "[INFO] Creating a 16GiB img..."
    dd if=/dev/zero of="$1/lfs_device.img" bs=16M count=1024 status=progress
}

get_dev_type() {

    local dev_type

    echo $1 | grep -E "^\/dev\/sd[a-z].*$" &> /dev/null
    if [ $? == 0 ]; then
        dev_type="dev"
    else
        dev_type="loop"
    fi

    echo $dev_type
}

exec_chroot() {

chroot "$LFS" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    MAKEFLAGS="-j$(nproc)" \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login -c "/root/$1 $2"
}

enter_chroot() {

chroot "$LFS" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    MAKEFLAGS="-j$(nproc)" \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login
}

check_error() {
    if [ $? != 0 ]; then
        echo "[ERROR] "$1" returned a non zero code!" | \
		tee -a $LFS/sources/build_lfs.log
	exit 1
    fi
}

check_error_chapter() {
    cat $LFS/sources/build_lfs.log | grep -i "error"
    if [ $? == 0 ]; then
        echo "[ERROR] Something went wrong in Chapter $1. Please check ${LFS}/sources/build_lfs.log"
	exit 1
    fi
}

create_backup() {

    if [ -z "$2" ]; then
        echo "[ERROR] Please provide the output path"
        exit 1
    elif [ ! -d "$2" ]
    then
        echo "[ERROR] Please provide a valid output path"
        exit 1
    fi

    pushd ${2}
    echo "[INFO] Creating backup ..."
    if [ "$1" == "dev" ]; then
        tar -cJpf lfs-temp-tools-12.2.tar.xz $LFS 
    elif [ "$1" == "loop" ]; then
        tar -cJf lfs_crosschain-12.2.tar.xz lfs_device.img
    fi
    popd

    # RESTARTING
    #cd $LFS
    #rm -rf ./*
    #tar -xpf $HOME/lfs-temp-tools-12.2.tar.xz
}
