/****************************************************************
 *  This is a simple example demonstrating an error with KLEE
 *    for a true assert statement.  
 ***************************************************************/
#include <assert.h>

void checkValidRange(int a, int b)
{
   assert(a == 2*b);
}

int main (int argc, char * argv[])
{

  int myInt = 0;
  int yourInt = 0;

  klee_make_symbolic(&myInt, sizeof(myInt), "myInt"); 
  klee_make_symbolic(&yourInt, sizeof(yourInt), "yourInt"); 

  checkValidRange(myInt, yourInt);
  return 0;
}

