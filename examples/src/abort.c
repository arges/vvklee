/****************************************************************
 *  This is a simple example demonstrating an error with KLEE
 *    for a call to abort.  
 ***************************************************************/ 
#include <string.h>
#include <stdlib.h>

int main (int argc, char * argv[])
{

   char myStr[5];

   klee_make_symbolic(&myStr, sizeof(myStr), "myStr");   
   if(strcmp(myStr, "bye!") == 0)
   {
       // someone said bye, time to go! 
       abort();
   }

   return 0;
}

