#!/bin/bash
#
# Script to run coreutils tests and output proper data.
#
# (C)2012 by Chris J Arges <christopherarges@gmail.com>
#

CWD=$(pwd)
EXAMPLES_DIR=${CWD}/examples
EXAMPLES_LLVM_DIR=${EXAMPLES_DIR}/obj-llvm
EXAMPLES_GCOV_DIR=${EXAMPLES_DIR}/obj-gcov

TIMESTAMP=$(date +%Y%m%d%H%M%S)
RESULT_DIR=${CWD}/results/$TIMESTAMP

# program names to skip
SKIP="(expr|nohup|yes|setuidgid|stty)"

function cleanup() {
	# Remove any gcov generated files.
	cd $EXAMPLES_GCOV_DIR
	rm -f *.gcda

	cd $EXAMPLES_DIR/src
	rm -f *.gcda

	# Remove any klee directories.
	cd $EXAMPLES_LLVM_DIR
	rm -rf klee-*
}

# run_example <binary_name> <arguments> <test #>
function run_example() {
	BINARY=$1
	ARGS=$2
	TESTNO=$3

	# setup the test
	echo ">>> testing $BINARY : $ARGS"
	cleanup
        cd ${EXAMPLES_LLVM_DIR}

	START=$(date +%s)
	TEST_DIR=${RESULT_DIR}/${BINARY}/${TESTNO}/
	mkdir -p ${TEST_DIR}

	# run klee coverage
	klee --only-output-states-covering-new --optimize --libc=uclibc \
		--posix-runtime ./${BINARY}.o ${ARGS} &> ${TEST_DIR}/klee.log
	klee-stats klee-last &>> ${TEST_DIR}/klee-stats.log
	ktest-tool klee-last/*.ktest &>> ${TEST_DIR}/ktest-tool.log
	cp -Lr klee-last ${TEST_DIR}/

	# calculate coverage of test
        cd $EXAMPLES_GCOV_DIR
	klee-replay ./${BINARY} ${TEST_DIR}/klee-last/*.ktest &>> \
		${TEST_DIR}/klee-replay.log

        #since I do not use a makefile, the coverage files
        #are put int the source directory, so navigate there 
        #to run gcov
        mv ../src/*.gcov ../src/*.gcda ../src/*.gcno .
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

function run_examples() {
	echo ${RESULT_DIR}
	mkdir -p ${RESULT_DIR}
	add_to_path	

	# run tests
	cd ${EXAMPLES_LLVM_DIR}
	for i in $(ls *.o ); do
		run_example ${i%.o} "--sym-arg 2 " 0
	done
}

while getopts "e?" opt; do
	case $opt in
	e)	run_examples;;
	*)	echo "Usage: $0 -e"
		echo "	-t\trun examples"
		;;
	esac
done

