#!/bin/bash 
#
# Script to run coreutils tests and output proper data.
#
# Works with both CDE package or custom built package.
#
# (C)2012 by Chris J Arges <christopherarges@gmail.com>
#

CWD=$(pwd)
TARGET_DIR=${CWD}/coreutils-klee/coreutils-8.16/
LLVM_DIR=${TARGET_DIR}/obj-llvm
GCOV_DIR=${TARGET_DIR}/obj-gcov

TIMESTAMP=$(date +%Y%m%d%H%M%S)
RESULT_DIR=${CWD}/results/$TIMESTAMP

KLEE_BIN="klee${KLEE_POSTFIX}"
KLEE_STATS_BIN="klee-stats${KLEE_POSTFIX}"
KTEST_TOOL_BIN="ktest-tool${KLEE_POSTFIX}"
KLEE_REPLAY_BIN="klee-replay${KLEE_POSTFIX}"
KLEE_PATH="$(pwd)/build/klee/Release+Asserts/bin/"

#KLEE_ARGS="--only-output-states-covering-new --optimize --use-forked-stp \
#		--libc=uclibc --max-time=1800 --posix-runtime"

KLEE_ARGS="--simplify-sym-indices --max-memory=12288 --use-cex-cache \
	--disable-inlining --allow-external-sym-calls --watchdog \
	--max-memory-inhibit=false --only-output-states-covering-new \
	--optimize --use-forked-stp --libc=uclibc \
	--max-time=60 --posix-runtime"
function cleanup() {
	# Remove any gcov generated files.
	cd $GCOV_DIR/src
	rm -f *.gcda

	# Remove any klee directories.
	cd $LLVM_DIR/src
	rm -rf klee-*
}

# run_test <binary_name> <posix arguments> <klee arguments> <test #>
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
	${KLEE_BIN} ${KLEE_ARGS} ./${BINARY}.bc ${ARGS} &> ${TEST_DIR}/klee.log
	${KLEE_STATS_BIN} klee-last &> ${TEST_DIR}/klee-stats.log
	${KTEST_TOOL_BIN} klee-last/*.ktest &> ${TEST_DIR}/ktest-tool.log
	cp -Lr klee-last ${TEST_DIR}/

	# calculate coverage of test
	cd $GCOV_DIR/src
	${KLEE_REPLAY_BIN} ./${BINARY} ${TEST_DIR}/klee-last/*.ktest &> ${TEST_DIR}/klee-replay.log
	gcov ./${BINARY} &> ${TEST_DIR}/gcov.log

	# keep track of time
	END=$(date +%s)
	DIFF=$(( $END - $START ))
	echo "	execution time: $DIFF s" | tee ${TEST_DIR}/time.log

	# show interesting stuff on the screen
	egrep "(executed|File)" ${TEST_DIR}/gcov.log | cut -f 2 -d ':'
	echo ""
}

# add KLEE bin to the path
add_to_path() {
	if [ -d "${KLEE_PATH}" ] && [[ ":$PATH:" != *":${KLEE_PATH}:"* ]]; then
		PATH="$PATH:${KLEE_PATH}"
	fi
}

function run_tests() {
	echo ${RESULT_DIR}
	mkdir -p ${RESULT_DIR}
	add_to_path	
	echo $1 > ${RESULT_DIR}/type
	cd $LLVM_DIR/src

	case $1 in
	"small") run_test echo "--sym-arg 3" 0 ;;
	"medium") 
		for i in $(ls *.bc ); do
			run_test ${i%.bc} "--sym-args 0 2 4 --sym-files 2 2" 0
		done
		;;
	"large") 
		for i in $(ls *.bc ); do
			run_test ${i%.bc} "--sym-args 0 8 8 --sym-files 2 8" 0
		done
		;;
	"args")
		for i in {1..10}; do
			run_test date "--sym-args 0 ${i} 16" $i
		done
		;;
	esac
}

while getopts "smlac" opt; do
	case $opt in
	s)	run_tests "small";;
	m)	run_tests "medium";;
	l)	run_tests "large";;
	a)	run_tests "args";;
	c)
		KLEE_POSTFIX=".cde"
		KLEE_PATH="$(pwd)/klee-cde-package/bin"
		KLEE_BIN="klee${KLEE_POSTFIX}"
		KLEE_STATS_BIN="klee-stats${KLEE_POSTFIX}"
		KTEST_TOOL_BIN="ktest-tool${KLEE_POSTFIX}"
		KLEE_REPLAY_BIN="klee-replay${KLEE_POSTFIX}"
		;;
	\?)	echo "Usage: $0"
		echo "	-s	run SMALL test."
		echo "	-m	run MEDIUM test."
		echo "	-l	run LARGE test (run overnight!)."
		echo "	-a	run args comparison test."
		echo "	-c	use CDE package."
		;;
	esac
done

