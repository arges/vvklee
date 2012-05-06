#!/bin/bash
#
# Script to parse results.
#
# (C)2012 by Chris J Arges <christopherarges@gmail.com>
#

RESULTS_DIR=

function parse() {
	echo "Parsing $RESULTS_DIR..."

	# iterate through programs tested
	for prog in $(ls $RESULTS_DIR | grep -v "type"); do
		# iterate through runs of that program
		for run in $(ls ${RESULTS_DIR}/$prog ); do

			GCOV_OUT=$(egrep -A1 "File(.*)\.c" ${RESULTS_DIR}/$prog/$run/gcov.log | \
				cut -f 2 -d ':' | cut -f 4  -d '/' | tr "\'" ' '| cut -f 1 -d '%' | tr '\n' ',')

			KLEE_STAT_OUT=$(grep 'klee-last' ${RESULTS_DIR}/$prog/$run/klee-stats.log | \
				 cut -d '|' -f 3- | tr '|' ',')

			echo "$prog, $run, $GCOV_OUT, $KLEE_STAT_OUT"
		done
	done

}

while getopts "d:?" opt; do
	case $opt in
	d)	RESULTS_DIR=$OPTARG 
		parse
		;;
	*)	echo "Usage: $0 -r <results directory>"
		;;
	esac
done

