#!/bin/bash

if [ "$EUID" -ne 0 ]
then
    echo "Please run as root"
    exit 1
fi

if [ x"${LFS}" == "x"  ]; then
    echo "LFS variable is not set"
    exit 1
fi

if [ x"${LFS_VERSION}" == "x"  ]; then
    echo "LFS_VERSION variable is not set"
    exit 1
fi

#------------------------------------------------------------------------------
# CHAPTER 3
#------------------------------------------------------------------------------

mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources

cp ${BASE_DIR}/${LFS_VERSION}/pkgs/* $LFS/sources

# GitHub did not like this big file
#tar -xzvf ${BASE_DIR}/${LFS_VERSION}/pkgs/lfs_12.2_pkgs.tar.gz -C $LFS/sources --strip-components 1

chown root:root $LFS/sources/*

echo "[INFO] Source packages in place!"
