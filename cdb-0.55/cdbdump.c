#include <stdio.h>
#include "cdb.h"

void format()
{
  fputs("cdbdump: fatal: bad database format\n",stderr);
  exit(1);
}

void readerror()
{
  if (ferror(stdin)) { perror("cdbdump: fatal: unable to read"); exit(111); }
  format();
}

void main()
{
  uint32 eod;
  uint32 pos;
  uint32 klen;
  uint32 dlen;
  char buf[8];
  int i;
  int c;

  if (fread(buf,1,4,stdin) < 4) readerror();
  eod = cdb_unpack(buf);
  for (i = 4;i < 2048;++i) if (getchar() == EOF) readerror();

  pos = 2048;
  while (pos < eod) {
    if (eod - pos < 8) format();
    pos += 8;
    if (fread(buf,1,8,stdin) < 8) readerror();
    klen = cdb_unpack(buf);
    dlen = cdb_unpack(buf + 4);
    if (eod - pos < klen) format();
    pos += klen;
    if (eod - pos < dlen) format();
    pos += dlen;
    printf("+%lu,%lu:",(unsigned long) klen,(unsigned long) dlen);
    while (klen) {
      --klen;
      c = getchar();
      if (c == EOF) readerror();
      putchar(c);
    }
    fputs("->",stdout);
    while (dlen) {
      --dlen;
      c = getchar();
      if (c == EOF) readerror();
      putchar(c);
    }
    fputs("\n",stdout);
  }

  fputs("\n",stdout);

  exit(0);
}
