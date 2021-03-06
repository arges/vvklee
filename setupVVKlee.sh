#!/bin/bash
#
# Script to build and setup environment for our V&V project.
#
# (C)2012 by Chris J Arges <christopherarges@gmail.com>
#

# This has been tested on both 32 and 64 bit Lucid. 
# Versions of llvm-gcc > gcc4.2/llvm-2.8 don't have the --emit-llvm option.

MAKEOPTS="-j8"
CWD=$(pwd)

KLEE_DIR="${CWD}/build/klee"
KLEE_PATH="${CWD}/build/klee/scripts/klee-gcc"

IS_64_BIT="`file /sbin/init | grep 64-bit`"

if [ -n "$IS_64_BIT" ]; then
   UCLIBC_PLATFORM="x64"
   echo "Using 64 bit platform"
else
   UCLIBC_PLATFORM="i386"
   echo "Using 32 bit platform"
fi

KLEE_UCLIBC_FILE="klee-uclibc-0.02-${UCLIBC_PLATFORM}.tgz"

CDE_BUILD=
KLEE_CDE_PACKAGE="http://keeda.stanford.edu/~pgbovine/klee-cde-package.v2.tar.bz2"
KLEE_POSTFIX=""

function download() {
	echo "Downloading and installing required files."
	sudo apt-get install --force-yes build-essential wget autoconf automake

	# If custom build download/extact all files.
	if [ ! -n "$CDE_BUILD" ]; then
		mkdir build
		cd build

		# get dependencies
		sudo apt-get install --force-yes subversion \
			kcachegrind llvm-gcc-4.2
		sudo apt-get build-dep --force-yes llvm
	
		# llvm-2.8
		wget http://llvm.org/releases/2.8/llvm-2.8.tgz
		tar -xf llvm-2.8.tgz
		# uclibc-0.02 klee
		wget http://www.doc.ic.ac.uk/~cristic/klee/${KLEE_UCLIBC_FILE}
		tar -xf ${KLEE_UCLIBC_FILE}
		# klee from svn
		svn co http://llvm.org/svn/llvm-project/klee/trunk klee

		cd ..
	else	
		# download CDE package (if selected)
		if [ ! -e klee-cde-package.v2.tar.bz2 ]; then
			 wget ${KLEE_CDE_PACKAGE}
		fi
		if [ ! -d klee-cde-package ]; then
			tar -xf klee-cde-package.v2.tar.bz2
		fi
	fi
}

function build() {

	if [ ! -n "$CDE_BUILD" ]; then
		echo "Building projects"
	
		cd build
	
		# build llvm
		cd llvm-2.8
		LLVM_PATH=$(pwd)
		./configure --enable-optimized --enable-assertions
		make ${MAKEOPTS} || fail "make llvm failed!"
		cd ..
	
		# build klee-uclibc
		cd klee-uclibc-0.02-${UCLIBC_PLATFORM}
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
	else
		echo "Don't need to build anything for CDE"
	fi
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
	#${KLEE_DIR}/Release+Asserts/bin/klee --libc=uclibc --posix-runtime src/cat.bc --version || fail "Couldn't run basic klee test!"

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

while getopts "cdbhe?" opt; do
	case $opt in
	c)
		CDE_BUILD="yes"
		KLEE_POSTFIX=".cde"
		KLEE_PATH="$(pwd)/klee-cde-package/bin"
		KLEE_PATH="${CWD}/klee-cde-package/cde-root/home/pgbovine/klee/scripts/klee-gcc"
		;;
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

