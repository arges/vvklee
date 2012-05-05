#!/bin/bash 

function build_examples()
{
  cd examples
 
  mkdir llvm-obj
  mkdir gcov-obj

  cd src 

  for i in $(ls *.c); do
    #make the gcov binary
    gcc -c ${i} -g -o ../gcov-obj/${i%.c}.o -fprofile-arcs -ftest-coverage
  done

  for i in $(ls *.c); do
    #make the gcov binary
    llvm-gcc -emit-llvm -c ${i} -g -o ../llvm-obj/${i%.c}.o
  done
}

build_examples
