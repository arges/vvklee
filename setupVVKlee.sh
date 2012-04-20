#!/bin/bash
#
# Script to build and setup environment for our V&V project.
#
# (C)2012 by Chris J Arges <christopherarges@gmail.com>
#

# Right now this has only been tested on 32-bit Lucid.
# Versions of llvm-gcc > gcc4.2/llvm-2.8 don't have the --emit-llvm option.

MAKEOPTS="-j8"
CWD=$(pwd)

KLEE_DIR="${CWD}/build/klee"
KLEE_PATH="${CWD}/build/klee/scripts/klee-gcc"
KLEE_UCLIBC_FILE="klee-uclibc-0.02-i386.tgz"

function download() {
	echo "Downloading and installing required files."
	apt-get install build-essential subversion gcov
	apt-get install kcachegrind
	apt-get build-dep llvm
	apt-get install llvm-gcc-4.2

	# Download files
	mkdir build
	cd build

	# llvm-2.8
	wget http://llvm.org/releases/2.8/llvm-2.8.tgz
	tar -xf llvm-2.8.tgz
	# uclibc-0.02 klee
	wget http://www.doc.ic.ac.uk/~cristic/klee/${KLEE_UCLIBC_FILE}
	tar -xf ${KLEE_UCLIBC_FILE}
	# klee from svn
	svn co http://llvm.org/svn/llvm-project/klee/trunk klee
	cd ..
}

function build() {
	echo "Building projects"

	cd build

	# build llvm
	cd llvm-2.8
	LLVM_PATH=$(pwd)
	./configure --enable-optimized --enable-assertions
	make ${MAKEOPTS} || fail "make llvm failed!"
	cd ..

	# build klee-uclibc
	cd klee-uclibc-0.02-i386
	./configure --with-llvm=${LLVM_PATH}
	make ${MAKEOPTS} || fail "make klee-uclibc failed!"
	UCLIBC_PATH=$(pwd)
	cd ..

	# build klee
	cd klee
	./configure --with-llvm=${LLVM_PATH} --with-uclibc=${UCLIBC_PATH} --enable-posix-runtime
	make ENABLED_OPTIMIZED=1 ${MAKEOPTS} || fail "make klee failed!"
	make check
	make unittests
	cd ../..

	win
}

COREUTILS_VER=8.16
COREUTILS_ARCHIVE=coreutils-${COREUTILS_VER}.tar.xz
COREUTILS_DIR=coreutils-${COREUTILS_VER}
COREUTILS_URL=http://ftp.gnu.org/gnu/coreutils/${COREUTILS_ARCHIVE}

function example() {
	echo "Building coreutils example"
	mkdir -p coreutils-klee && cd coreutils-klee

	# download and extract if it doesn't exist
	if [ ! -e ${COREUTILS_ARCHIVE} ]; then wget ${COREUTILS_URL}; fi
	if [ ! -d ${COREUTILS_DIR} ]; then tar -xf ${COREUTILS_ARCHIVE}; fi
	cd ${COREUTILS_DIR}

	# patch system
	for i in $(ls ../../patch); do
		patch -p1 < ../../patch/$i
	done

	# build gcov tests
	mkdir -p obj-gcov && cd obj-gcov
	../configure --disable-nls CFLAGS="-g -fprofile-arcs -ftest-coverage"
	make ${MAKEOPTS} || fail "Couldn't build obj-gcov coreutils!"
	cd ..

	# build llvm objects
	mkdir -p obj-llvm && cd obj-llvm
	../configure --disable-nls CFLAGS="-g"
	make CC=${KLEE_PATH} CPPFLAGS="-std=gnu99" ${MAKEOPTS} || fail "Couldn't build obj-llvm coreutils!"

	# test it
	${KLEE_DIR}/Release+Asserts/bin/klee --libc=uclibc --posix-runtime src/cat.bc --version || fail "Couldn't run basic klee test!"

	cd ../..
	win
}

function fail() {
echo "     FAIL WHALE! "
echo ""
echo "W     W      W        "
echo "W        W  W     W   " 
echo "              '.  W    "  
echo "  .-\"\"-._     \ \.--|  "
echo " /       \"-..__) .-'   "
echo "|     _         /      "
echo "\'-.__,   .__.,\'       "
echo " \`\'----\'._\--\'      "
echo "VVVVVVVVVVVVVVVVVVVVV"
echo $1
exit 1
}

function win() {
echo "Huzzah! It works! :)"
}

while getopts "dbhe?" opt; do
	case $opt in
	d)	download ;;
	b)	build ;;
	e)	example ;;
	*)	echo "Usage: $0 -dbe"
		echo "	-d download files"
		echo "	-b build files"
		echo "	-e build coreutils example"
		;;
	esac
done

