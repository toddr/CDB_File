#include <sys/types.h>
#include <stdio.h>
#include "cdb.h"

#ifndef SEEK_SET
#define SEEK_SET 0
#endif
#ifndef SEEK_CUR
#define SEEK_CUR 1
#endif

void format()
{
  fputs("cdbtest: fatal: bad database format\n",stderr);
  exit(1);
}

void readerror()
{
  if (ferror(stdin)) { perror("cdbtest: fatal: unable to read"); exit(111); }
  format();
}

char key[1024];
int numtoolong = 0;
int numnotfound = 0;
int numotherpos = 0;
int numbadlen = 0;
int numfound = 0;

void main()
{
  int i;
  int c;
  uint32 eod;
  uint32 klen;
  uint32 pos;
  uint32 dlen;
  uint32 dlen2;
  char buf[8];

  if (cdb_bread(0,buf,4) == -1) readerror();
  eod = cdb_unpack(buf);

  pos = 2048;
  while (pos < eod) {
    if (lseek(0,(off_t) pos,SEEK_SET) == -1) readerror(); 

    if (eod - pos < 8) format();
    pos += 8;
    if (cdb_bread(0,buf,8) == -1) readerror();
    klen = cdb_unpack(buf);
    dlen = cdb_unpack(buf + 4);
    if (eod - pos < klen) format();
    pos += klen;

    if (klen > sizeof(key))
      ++numtoolong;
    else {
      if (cdb_bread(0,key,(int) klen) == -1) readerror();
      i = cdb_seek(0,key,(int) klen,&dlen2);
      if (i == -1) readerror();
      if (i == 0)
	++numnotfound;
      else
	if (lseek(0,(off_t) 0,SEEK_CUR) != pos)
	  ++numotherpos;
        else
	  if (dlen2 != dlen)
	    ++numbadlen;
	  else
	    ++numfound;
    }

    if (eod - pos < dlen) format();
    pos += dlen;
  }

  printf("found: %d\n",numfound);
  printf("different record: %d\n",numotherpos);
  printf("bad length: %d\n",numbadlen);
  printf("not found: %d\n",numnotfound);
  printf("too long to test: %d\n",numtoolong);
  exit(0);
}
