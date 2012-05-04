#!/bin/bash
#
# Script to run coreutils tests and output proper data.
# Must have working environment first, and klee* in path.
#
# (C)2012 by Chris J Arges <christopherarges@gmail.com>
#

CWD=$(pwd)
TARGET_DIR=${CWD}/coreutils-klee/coreutils-8.16/
LLVM_DIR=${TARGET_DIR}/obj-llvm
GCOV_DIR=${TARGET_DIR}/obj-gcov

TIMESTAMP=$(date +%Y%m%d%H%M%S)
RESULT_DIR=${CWD}/results/$TIMESTAMP

function cleanup() {
	# Remove any gcov generated files.
	cd $GCOV_DIR/src
	rm -f *.gcda

	# Remove any klee directories.
	cd $LLVM_DIR/src
	rm -rf klee-*
}

# run_test <binary_name> <sym args> <sym files>
function run_test() {
	BINARY=$1
	ARGS=$2

	cleanup
	echo ">>> testing $BINARY : $ARGS"
	START=$(date +%s)

	TEST_DIR=${RESULT_DIR}/${BINARY}/
	mkdir -p ${TEST_DIR}

	# run klee coverage
	klee --only-output-states-covering-new --optimize --libc=uclibc \
		--posix-runtime ./${BINARY}.bc ${ARGS} &> ${TEST_DIR}/klee.log
	klee-stats klee-last &>> ${TEST_DIR}/klee-stats.log
	ktest-tool klee-last/*.ktest &>> ${TEST_DIR}/ktest-tool.log
	cp -Lr klee-last ${TEST_DIR}/

	# calculate coverage of test
	cd $GCOV_DIR/src
	klee-replay ./${BINARY} ${TEST_DIR}/klee-last/*.ktest &>> \
		${TEST_DIR}/klee-replay.log
	gcov ./${BINARY} &>> ${TEST_DIR}/gcov.log

	# keep track of time
	END=$(date +%s)
	DIFF=$(( $END - $START ))
	echo "	execution time: $DIFF s"
	egrep "(executed|File)" ${TEST_DIR}/gcov.log | cut -f 2 -d ':'
	echo ""
}

function run_tests() {
	echo ${RESULT_DIR}
	mkdir -p ${RESULT_DIR}

	# run selected tests
	cd $LLVM_DIR/src
	run_test echo "--sym-args 0 2 4"
}

while getopts "t?" opt; do
	case $opt in
	t)	run_tests;;
	*)	echo "Usage: $0 -t"
		echo "	-t\trun test"
		;;
	esac
done

