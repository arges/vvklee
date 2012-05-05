#include <string.h>

int main (int argc, char * argv[])
{

  int myInt = 0;
  int yourInt = 0;

  if (argc == 2 )
  {
     
     if(strcmp(argv[1], "1") == 0)
     {
       yourInt = 1;
     }
     else
     {
       yourInt = 10;
     }
  
     myInt = yourInt-1;

     return yourInt/myInt;

   }

   return 0;
}

