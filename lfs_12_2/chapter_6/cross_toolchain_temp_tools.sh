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

cd $LFS/sources

source ${HOME}/utils.sh

#------------------------------------------------------------------------------
# CHAPTER 6
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# M4-1.4.19
#------------------------------------------------------------------------------

install_m4_tmp() {

extr_enter_pkg "m4"

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

check_error "configure m4_tmp"

make
check_error "make m4_tmp"
make DESTDIR=$LFS install
check_error "make install m4_tmp"

cd $LFS/sources

rm_pkg "m4"
}

#------------------------------------------------------------------------------
# Ncurses-6.5
#------------------------------------------------------------------------------

install_ncurses_tmp() {

extr_enter_pkg "ncurses"

sed -i s/mawk// configure

mkdir build

pushd build
../configure
make -C include
make -C progs tic
popd

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(./config.guess) \
            --mandir=/usr/share/man \
            --with-manpage-format=normal \
            --with-shared \
            --without-normal \
            --with-cxx-shared \
            --without-debug \
            --without-ada \
            --disable-stripping

check_error "configure ncurses_tmp"

make
check_error "make ncurses_tmp"
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
check_error "make install ncurses_tmp"

ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h

rm_pkg "ncurses"
}

#------------------------------------------------------------------------------
# Bash-5.2
#------------------------------------------------------------------------------

install_bash_tmp() {

extr_enter_pkg "bash"

./configure --prefix=/usr \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT \
            --without-bash-malloc \
            bash_cv_strtold_broken=no

check_error "configure bash_tmp"

make
check_error "make bash_tmp"
make DESTDIR=$LFS install
check_error "make install bash_tmp"

ln -sv bash $LFS/bin/sh

rm_pkg "bash"
}

#------------------------------------------------------------------------------
# Coreutils-9.5
#------------------------------------------------------------------------------

install_coreutils_tmp() {

extr_enter_pkg "coreutils"

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime

check_error "configure coreutils_tmp"

make
check_error "make coreutils_tmp"
make DESTDIR=$LFS install
check_error "make install coreutils_tmp"

mv -v $LFS/usr/bin/chroot $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' $LFS/usr/share/man/man8/chroot.8

rm_pkg "coreutils"
}

#------------------------------------------------------------------------------
# Diffutils-3.10
#------------------------------------------------------------------------------

install_diffutils_tmp() {

extr_enter_pkg "diffutils"

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

check_error "configure difftils_tmp"

make
check_error "make difftils_tmp"
make DESTDIR=$LFS install
check_error "make install difftils_tmp"

rm_pkg "diffutils"
}

#------------------------------------------------------------------------------
# File-5.45
#------------------------------------------------------------------------------

install_file_tmp() {

extr_enter_pkg "file"

mkdir build

pushd build
../configure --disable-bzlib \
             --disable-libseccomp \
             --disable-xzlib \
             --disable-zlib

check_error "configure file_tmp"

make
check_error "make file_tmp"
popd

./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)

make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
check_error "make install file_tmp"

rm -v $LFS/usr/lib/libmagic.la

rm_pkg "file"
}

#------------------------------------------------------------------------------
# Findutils-4.10.0
#------------------------------------------------------------------------------

install_findutils_tmp() {

#supply xargs
extr_enter_pkg "findutils"

./configure --prefix=/usr \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess) 

check_error "configure findutils_tmp"

make
check_error "make findutils_tmp"
make DESTDIR=$LFS install
check_error "make install findutils_tmp"

rm_pkg "findutils"
}

#------------------------------------------------------------------------------
# Gawk-5.3.0
#------------------------------------------------------------------------------

install_gawk_tmp() {

extr_enter_pkg "gawk"

sed -i 's/extras//' Makefile.in

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

check_error "configure gawk_tmp"

make
check_error "make gawk_tmp"
make DESTDIR=$LFS install
check_error "make install gawk_tmp"

rm_pkg "gawk"
}

#------------------------------------------------------------------------------
# Grep-3.11
#------------------------------------------------------------------------------

install_grep_tmp() {

extr_enter_pkg "grep"

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

check_error "configure grep_tmp"

make
check_error "make grep_tmp"
make DESTDIR=$LFS install
check_error "make install grep_tmp"

rm_pkg "grep"
}

#------------------------------------------------------------------------------
# Gzip-1.13
#------------------------------------------------------------------------------

install_gzip_tmp() {

extr_enter_pkg "gzip"

./configure --prefix=/usr --host=$LFS_TGT

check_error "configure gzip_tmp"

make
check_error "make gzip_tmp"
make DESTDIR=$LFS install
check_error "make install gzip_tmp"

rm_pkg "gzip"
}

#------------------------------------------------------------------------------
# Make-4.4.1
#------------------------------------------------------------------------------

install_make_tmp() {

extr_enter_pkg "make"

./configure --prefix=/usr \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

check_error "configure make_tmp"

make
check_error "make make_tmp"
make DESTDIR=$LFS install
check_error "make install make_tmp"

rm_pkg "make"
}

#------------------------------------------------------------------------------
# Patch-2.7.6
#------------------------------------------------------------------------------

install_patch_tmp() {

extr_enter_pkg "patch"

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

check_error "configure patch_tmp"

make
check_error "make patch_tmp"
make DESTDIR=$LFS install
check_error "make install patch_tmp"

rm_pkg "patch"
}

#------------------------------------------------------------------------------
# Sed-4.9
#------------------------------------------------------------------------------

install_sed_tmp() {

extr_enter_pkg "sed"

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

check_error "configure sed_tmp"

make
check_error "make sed_tmp"
make DESTDIR=$LFS install
check_error "make install sed_tmp"

rm_pkg "sed"
}

#------------------------------------------------------------------------------
# Tar-1.35
#------------------------------------------------------------------------------

install_tar_tmp() {

extr_enter_pkg "tar"

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

check_error "configure tar_tmp"

make
check_error "make tar_tmp"
make DESTDIR=$LFS install
check_error "make install tar_tmp"

rm_pkg "tar"
}

#------------------------------------------------------------------------------
# Xz-5.6.2
#------------------------------------------------------------------------------

install_xz_tmp() {

extr_enter_pkg "xz"

./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess) \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.6.2

check_error "configure xz_tmp"

make
check_error "make xz_tmp"
make DESTDIR=$LFS install
check_error "make install xz_tmp"

rm -v $LFS/usr/lib/liblzma.la

rm_pkg "xz"
}

#------------------------------------------------------------------------------
# Binutils-2.43.1 - Pass 2
#------------------------------------------------------------------------------

install_binutils_pass2() {

extr_enter_pkg "binutils"

#rm -r gdb* libbacktrace libdecnumber contrib djunpack.bat COPYING.LIBGLOSS \
#        COPYING.NEWLIB gnulib readline || true

sed '6009s/$add_dir//' -i ltmain.sh

mkdir -v build
cd build

../configure \
    --prefix=/usr \
    --build=$(../config.guess) \
    --host=$LFS_TGT \
    --disable-nls \
    --enable-shared \
    --enable-gprofng=no \
    --disable-werror \
    --enable-64-bit-bfd \
    --enable-new-dtags \
    --enable-default-hash-style=gnu

check_error "configure binutils_pass2"

make
check_error "make binutils_pass2"
make DESTDIR=$LFS install
check_error "make installbinutils_pass2"

rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

rm_pkg "binutils"
}

#------------------------------------------------------------------------------
# GCC-14.2.0 - Pass 2
#------------------------------------------------------------------------------

install_gcc_pass2() {

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

sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir -v build && cd build

../configure \
    --build=$(../config.guess) \
    --host=$LFS_TGT \
    --target=$LFS_TGT \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc \
    --prefix=/usr \
    --with-build-sysroot=$LFS \
    --enable-default-pie \
    --enable-default-ssp \
    --disable-nls \
    --disable-multilib \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libsanitizer \
    --disable-libssp \
    --disable-libvtv \
    --enable-languages=c,c++

check_error "configure gcc_pass2"

make
check_error "make gcc_pass2"
make DESTDIR=$LFS install
check_error "make install gcc_pass2"

ln -sv gcc $LFS/usr/bin/cc

rm_pkg "gcc"
}

install_m4_tmp
install_ncurses_tmp
install_bash_tmp
install_coreutils_tmp
install_diffutils_tmp
install_file_tmp
install_findutils_tmp
install_gawk_tmp
install_grep_tmp
install_gzip_tmp
install_make_tmp
install_patch_tmp
install_sed_tmp
install_tar_tmp
install_xz_tmp
install_binutils_pass2
install_gcc_pass2

echo "[INFO] Cross toolchain temporary tools compiled!"
