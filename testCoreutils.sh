#!/bin/bash
#
# Script to run coreutils tests and output proper data.
#
# (C)2012 by Chris J Arges <christopherarges@gmail.com>
#

CWD=$(pwd)
TARGET_DIR=${CWD}/coreutils-klee/coreutils-8.16/
LLVM_DIR=${TARGET_DIR}/obj-llvm
GCOV_DIR=${TARGET_DIR}/obj-gcov

TIMESTAMP=$(date +%Y%m%d%H%M%S)
RESULT_DIR=${CWD}/results/$TIMESTAMP

# program names to skip
SKIP="(expr|nohup|yes|setuidgid|stty|cp|ginstall|mv|runcon|shred|sort|tail|timeout)"

function cleanup() {
	# Remove any gcov generated files.
	cd $GCOV_DIR/src
	rm -f *.gcda

	# Remove any klee directories.
	cd $LLVM_DIR/src
	rm -rf klee-*
}

# run_test <binary_name> <arguments> <test #>
function run_test() {
	BINARY=$1
	ARGS=$2
	TESTNO=$3

	# setup the test
	echo ">>> testing $BINARY : $ARGS"
	cleanup
	START=$(date +%s)
	TEST_DIR=${RESULT_DIR}/${BINARY}/${TESTNO}/
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
	echo "	execution time: $DIFF s" | tee ${TEST_DIR}/time.log

	# show interesting stuff on the screen
	egrep "(executed|File)" ${TEST_DIR}/gcov.log | cut -f 2 -d ':'
	echo ""
}

# add klee to the path
add_to_path() {
	KLEE_BIN="$(pwd)/build/klee/Release+Asserts/bin/"
	if [ -d "${KLEE_BIN}" ] && [[ ":$PATH:" != *":${KLEE_BIN}:"* ]]; then
		PATH="$PATH:${KLEE_BIN}"
	fi
}

function run_tests() {
	echo ${RESULT_DIR}
	mkdir -p ${RESULT_DIR}
	add_to_path	

	# run tests
	cd $LLVM_DIR/src
	for i in $(ls *.bc | egrep -v $SKIP); do
		run_test ${i%.bc} "--sym-args 10 2 2 --sym-files 2 8 --max-time=60" 0
	done
}

while getopts "t?" opt; do
	case $opt in
	t)	run_tests;;
	*)	echo "Usage: $0 -t"
		echo "	-t\trun test"
		;;
	esac
done

