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
# CHAPTER 4
#------------------------------------------------------------------------------

mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

for i in bin lib sbin
do
    ln -sv usr/$i $LFS/$i
done

case $(uname -m) in
    x86_64) mkdir -pv $LFS/lib64 ;;
esac

mkdir -pv $LFS/tools

groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
echo "lfs" | passwd --stdin lfs

chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
case $(uname -m) in
    x86_64) chown -v lfs $LFS/lib64 ;;
esac

# Extra: quick workaround to delete the extracted folders
chown -v lfs $LFS/sources

[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE

cp -v $BASE_DIR/$LFS_VERSION/chapter_4/set_lfs_env.sh /home/lfs

#su - lfs

sudo -u lfs bash << EOF
bash ~/set_lfs_env.sh
EOF

#------------------------------------------------------------------------------
#gcc -dumpmachine
#readelf -l <name of binary> | grep interpreter
#------------------------------------------------------------------------------

echo "[INFO] \"lfs\" user added!"
