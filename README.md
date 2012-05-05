vvklee
======

Verification and Validation Project Using KLEE

Written by:
	Chris J Arges <christopherarges@gmail.com>
	Jennifer Kaser <jennifer.kaser@gmail.com>

Notes:
	Has support for using a custom built toolchain and the CDE package.
	So far CDE package does not work as well and it experimental.

Usage:
	# First build a toolchain (download, build, build example)
	./setupVVKlee -dbe

	# Now run tests on the example
	./testCoreutils.sh -s

