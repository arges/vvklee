#!/bin/bash 

function build_examples()
{
  cd examples
 
  mkdir obj-llvm
  mkdir obj-gcov

  cd src 

  for i in $(ls *.c); do
    #make the gcov binary
    gcc ${i} -g -o ../obj-gcov/${i%.c} -fprofile-arcs -ftest-coverage
  done

  for i in $(ls *.c); do
    #make the gcov binary
    llvm-gcc -emit-llvm -c ${i} -g -o ../obj-llvm/${i%.c}.o
  done
}

build_examples
