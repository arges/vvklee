/****************************************************************
 *  This is a simple example demonstrating an error with KLEE
 *    for a divide by zero error.  
 ***************************************************************/
#include <string.h>

int main (int argc, char * argv[])
{

  int myInt = 0;
  int yourInt = 0;

  klee_make_symbolic(&yourInt, sizeof(yourInt), "yourInt");
  klee_make_symbolic(&myInt, sizeof(myInt), "myInt");

  myInt = yourInt-1;

  // this will cause a divide by zero sometimes
  return yourInt/myInt;

}

