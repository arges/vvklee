/****************************************************************
 *  This is a simple example demonstrating an error with KLEE
 *    for a buffer overflow problem or pointer issue. 
 ***************************************************************/
#include <string.h>


void copyBuffer(char * bof)
{
   char buf[8];

   // oh no! we did not check the buffer sizes we are copying
   strcpy(buf, bof);
}

int main (int argc, char * argv[])
{

   char myStr[20];
   int x;

   klee_make_symbolic(&myStr, sizeof(myStr), "myStr");

   // make a constraint that the first 7 characters are non-null
   // so that we will produce 3 different test cases, one with ane
   // error, one on the boundary condition and one with an error 
   for (x=0; x< 7; x++)
   {
      klee_assume(myStr[x] != '\0'); 
   }

   copyBuffer(myStr);

   return 0;
}

