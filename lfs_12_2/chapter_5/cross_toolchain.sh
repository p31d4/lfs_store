#!/bin/bash

#source ~/.bash_profile
source ~/.bashrc

if [ $(whoami) != "lfs" ]; then
    echo "User is not lfs, exiting..."
    exit 1
fi

if [ x"${LFS}" == "x" ]; then
    echo "LFS variable is not set"
    exit 1
fi

if [ x"${LFS_TGT}" == "x" ]; then
    echo "LFS_TGT variable is not set"
    exit 1
fi

source ~/utils.sh

#------------------------------------------------------------------------------
# Binutils-2.43.1 - Pass 1
#------------------------------------------------------------------------------

install_binutils_pass1() {

extr_enter_pkg "binutils"

#rm -r gdb* libbacktrace libdecnumber contrib djunpack.bat COPYING.LIBGLOSS \
#        COPYING.NEWLIB gnulib readline || true

mkdir -v build
cd build

../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT \
             --disable-nls \
             --enable-gprofng=no \
             --disable-werror \
             --enable-new-dtags \
             --enable-default-hash-style=gnu

check_error "configure binutils_pass1"

make
check_error "make binutils_pass1"
make install
check_error "make install binutils_pass1"

rm_pkg "binutils"
}

#------------------------------------------------------------------------------
# GCC-14.2.0 - Pass 1
#------------------------------------------------------------------------------

install_gcc_pass1() {

extr_enter_pkg "gcc"

tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc

case $(uname -m) in
    x86_64)
        sed -e '/m64=/s/lib64/lib/' \
            -i.orig gcc/config/i386/t-linux64
    ;;
esac

mkdir -v build
cd build

../configure \
    --target=$LFS_TGT \
    --prefix=$LFS/tools \
    --with-glibc-version=2.40 \
    --with-sysroot=$LFS \
    --with-newlib \
    --without-headers \
    --enable-default-pie \
    --enable-default-ssp \
    --disable-nls \
    --disable-shared \
    --disable-multilib \
    --disable-threads \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libssp \
    --disable-libvtv \
    --disable-libstdcxx \
    --enable-languages=c,c++

check_error "configure gcc_pass1"

make
check_error "make gcc_pass1"
make install
check_error "make install gcc_pass1"

cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
    `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h

rm_pkg "gcc"
}

#------------------------------------------------------------------------------
# Linux-6.10.5 API Headers
#------------------------------------------------------------------------------

install_linux_api_headers() {

extr_enter_pkg "linux"

make mrproper
make headers
check_error "make headers linux_api_headers"

find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr

rm_pkg "linux"
}

#------------------------------------------------------------------------------
# Glibc-2.40
#------------------------------------------------------------------------------

install_glibc_tmp() {

extr_enter_pkg "glibc"

# cmd: info coreutils ln
case $(uname -m) in
    i?86) ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac

# FHS - Filesystem Hierarchy Standard
patch -Np1 -i ../glibc-2.40-fhs-1.patch

mkdir -v build && cd build

# ensure that ldconfig and sln are in /usr/bin
#if ! command -v ldconfig 2>&1 >/dev/null
if [ ! -f /usr/sbin/ldconfig ]
then
    echo "ldconfig not available! Exiting..."
    exit 1
fi

if [ ! -f /usr/sbin/ldconfig ]
then
    echo "sln not available! Exiting..."
    exit 1
fi

echo "rootsbindir=/usr/sbin" > configparms

../configure \
    --prefix=/usr \
    --host=$LFS_TGT \
    --build=$(../scripts/config.guess) \
    --enable-kernel=4.19 \
    --with-headers=$LFS/usr/include \
    --disable-nscd \
    libc_cv_slibdir=/usr/lib

# missing or incompatible msgfmt is generally harmless
check_error "configure glibc_tmp"

make
check_error "make glibc_tmp"
make DESTDIR=$LFS install
check_error "make install glibc_tmp"

sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

echo 'int main(){}' | $LFS_TGT-gcc -xc -
readelf -l a.out | grep ld-linux
rm -v a.out

rm_pkg "glibc"
}

#------------------------------------------------------------------------------
# Libstdc++ from GCC-14.2.0
#------------------------------------------------------------------------------

install_libstdcpp() {

extr_enter_pkg "gcc"

mkdir -v build && cd build

../libstdc++-v3/configure \
    --host=$LFS_TGT \
    --build=$(../config.guess) \
    --prefix=/usr \
    --disable-multilib \
    --disable-nls \
    --disable-libstdcxx-pch \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/14.2.0

check_error "configure libstdcpp"

make
check_error "make libstdcpp"
make DESTDIR=$LFS install
check_error "make install libstdcpp"

rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la

rm_pkg "gcc"
}

#------------------------------------------------------------------------------
# Install packages
#------------------------------------------------------------------------------

install_binutils_pass1
install_gcc_pass1
install_linux_api_headers
install_glibc_tmp
install_libstdcpp

echo "[INFO] Base cross toolchain compiled!"
