#!/bin/bash

WORK_DIR="$(pwd)/binutils_sbu"

compile_binutils_pass1() {

mkdir -v {build,tmp_dir}
cd build

../configure --prefix=${WORK_DIR}/tmp_dir \
             --with-sysroot=/ \
             --target=$(uname -m)-linux-gnu \
             --disable-nls \
             --enable-gprofng=no \
             --disable-werror \
             --enable-new-dtags \
             --enable-default-hash-style=gnu

make
make install

echo "[INFO] For your system 1 SBU is around:"
}

#echo "Cloning binutils repo..."
#git clone -c advice.detachedHead=false --depth 1 --branch binutils-2_43_1 \
#	https://sourceware.org/git/binutils-gdb.git binutils_sbu

wget https://sourceware.org/pub/binutils/releases/binutils-2.43.1.tar.xz
mkdir -pv ${WORK_DIR}
tar -xvf binutils-2.43.1.tar.xz -C ${WORK_DIR} --strip-components 1

cd binutils_sbu
#rm -r gdb* libbacktrace libdecnumber contrib djunpack.bat COPYING.LIBGLOSS \
#        COPYING.NEWLIB gnulib readline

time compile_binutils_pass1

cd ${WORK_DIR}/..
sudo rm -r binutils_sbu
