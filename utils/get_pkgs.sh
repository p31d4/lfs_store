#!/bin/bash

usage() {
    echo "    usage: $1 <LFS_VERSION>        - LFS version for the downloaded packages"
    exit 1
}

if [ -z "$1" ]
then
    usage $0
fi

if [ x"${LFS_VERSION}" == "x" ];then
    LFS_VERSION=$1
fi

if [ x"${BASE_DIR}" == "x" ]; then
    BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/..
fi

WORK_DIR=${BASE_DIR}/${LFS_VERSION}/pkgs

get_pkg() {

    local url
    local pkg_name

    pkg_name="$1-$3"

    if [ -e "${BASE_DIR}/${LFS_VERSION}/pkgs/${pkg_name}.tar.xz" ]; then
        echo "[INFO] Package ${pkg_name}.tar.xz already exists!"
        return
    fi

    # Read url from common file
    url=$(grep "^$1" ${BASE_DIR}/urls | cut -d" " -f2)
    # depth 2 is required otherwise the the repo won't be recognized as a
    # git repo and the bootstrap (autoconf) acripts will find a UNKKOWN version
    # making the script fail
    git clone -c advice.detachedHead=false --depth 2 --branch $2 ${url} ${pkg_name}

    if [ x"$4" != "x"  ]; then
        echo "[INFO] Running preparation command: ${4}"
	pushd ${pkg_name}
	bash_cmd=$(echo $4 | tr -d '"')
        bash -c "${bash_cmd}"
	if [ $? != 0 ]; then
            echo "[ERROR] Error generating package ${pkg_name}"
	    exit 1
        fi
	popd
    fi

    echo -e "\n[INFO] Packing ${pkg_name}...\n"
    rm -r ${pkg_name}/.git
    tar -cJf "${pkg_name}.tar.xz" "${pkg_name}"
    rm -r "${pkg_name}"
}

#******************************************************************************

source ${BASE_DIR}/utils/utils.sh

mkdir -pv ${WORK_DIR}
pushd ${WORK_DIR}

sed -e 's/[[:space:]]*#.*// ; /^[[:space:]]*$/d' "${BASE_DIR}/${LFS_VERSION}/versions" |
    while read pkg_alias pkg_tag pkg_version gen_cmd; do
        print_80x "-"
	echo "[INFO] getting package ${pkg_alias}"
        print_80x "-"
	get_pkg ${pkg_alias} ${pkg_tag} ${pkg_version} "${gen_cmd}"
	sleep 0.2
    done

cp ${BASE_DIR}/common_pkgs/*tar.{xz,gz,bz2} ${WORK_DIR} 2> /dev/null
cp ${BASE_DIR}/${LFS_VERSION}/weird_stuff/*tar.{xz,gz,bz2} ${WORK_DIR} 2> /dev/null
cp ${BASE_DIR}/${LFS_VERSION}/data/*tar.{xz,gz,bz2} ${WORK_DIR} 2> /dev/null
cp ${BASE_DIR}/${LFS_VERSION}/patches/* ${WORK_DIR}
