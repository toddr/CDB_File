#include <stdio.h>
#include "cdb.h"

void main(argc,argv)
int argc;
char **argv;
{
  uint32 len;
  int c;

  if (!argv[1]) {
    fputs("cdbget: usage: cdbget key\n",stderr);
    exit(2);
  }

  switch(cdb_seek(0,argv[1],strlen(argv[1]),&len)) {
    case -1:
      perror("cdbget: fatal");
      exit(111);
    case 0:
      exit(1);
  }

  /* We'll use stdio to read the next len bytes from fd 0. */

  while (len--) {
    c = getchar();
    if (c == EOF) {
      fputs("cdbget: fatal: out of data\n",stderr);
      exit(111);
    }
    putchar(c);
  }

  exit(0);
}
