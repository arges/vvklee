/****************************************************************
 *  This is a simple example demonstrating an error with KLEE
 *    for multiple calls to free.  
 ***************************************************************/

int doSomething(int x, void * buf)
{
   if (x%3 == 2)
   {
      free((void*)buf);
      return 0;
   }

   return 1;
}

int main (int argc, char * argv[])
{

   int x;
   int * myBuf = (int *)malloc(sizeof(int)*20);

   klee_make_symbolic(&x, sizeof(x), "x");

   if (!doSomething(x, myBuf))
   {
      free((void *)myBuf);
   }

   return 0;
}

