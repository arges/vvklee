#!/bin/bash 


KLEE_LIB_DIR="`pwd`/build/klee/Release+Asserts/lib"

function build_examples()
{
  cd examples
 
  mkdir obj-llvm
  mkdir obj-gcov

  cd src 

  for i in $(ls *.c); do
    #make the gcov binary
    gcc ${i} -g -o ../obj-gcov/${i%.c} -fprofile-arcs -ftest-coverage  -lkleeRuntest -L${KLEE_LIB_DIR}
  done

  for i in $(ls *.c); do
    #make the gcov binary
    llvm-gcc -emit-llvm -c ${i} -g -o ../obj-llvm/${i%.c}.o
  done
}

build_examples
