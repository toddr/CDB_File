#include <stdio.h>
#include "cdb.h"

#ifndef SEEK_SET
#define SEEK_SET 0
#endif

void format()
{
  fputs("cdbstats: fatal: bad database format\n",stderr);
  exit(1);
}

void readerror()
{
  if (ferror(stdin)) { perror("cdbstats: fatal: unable to read"); exit(111); }
  format();
}

char pointers[2048];
char buf[8];

void main()
{
  uint32 pos;
  int i;
  uint32 len;
  uint32 slot;
  uint32 records;
  uint32 slots;
  uint32 d0;
  uint32 d1;
  uint32 d2;
  uint32 d3;
  uint32 d4;
  uint32 d5;
  uint32 d6;
  uint32 d7;
  uint32 d8;
  uint32 d9;
  uint32 dfar;
  uint32 h;
  uint32 where;

  if (fread(pointers,1,2048,stdin) < 2048) readerror();
  pos = cdb_unpack(pointers);

  if (fseek(stdin,(unsigned long) pos,SEEK_SET) == -1) {
    perror("cdbstats: fatal: unable to seek");
    exit(111);
  }

  dfar = d9 = d8 = d7 = d6 = d5 = d4 = d3 = d2 = d1 = d0 = records = slots = 0;
  for (i = 0;i < 256;++i) {
    len = cdb_unpack(pointers + 8 * i + 4);
    slots += len;
    for (slot = 0;slot < len;++slot) {
      if (fread(buf,1,8,stdin) < 8) readerror();
      if (cdb_unpack(buf + 4)) {
	++records;
	h = cdb_unpack(buf);
	if ((h & 255) != i) format();
	where = (h >> 8) % len;
	if (where == slot) { ++d0; continue; }
	if (++where == len) where = 0;
	if (where == slot) { ++d1; continue; }
	if (++where == len) where = 0;
	if (where == slot) { ++d2; continue; }
	if (++where == len) where = 0;
	if (where == slot) { ++d3; continue; }
	if (++where == len) where = 0;
	if (where == slot) { ++d4; continue; }
	if (++where == len) where = 0;
	if (where == slot) { ++d5; continue; }
	if (++where == len) where = 0;
	if (where == slot) { ++d6; continue; }
	if (++where == len) where = 0;
	if (where == slot) { ++d7; continue; }
	if (++where == len) where = 0;
	if (where == slot) { ++d8; continue; }
	if (++where == len) where = 0;
	if (where == slot) { ++d9; continue; }
	++dfar;
      }
    }
  }

  printf("slots\t%9lu\n",(unsigned long) slots);
  printf("records\t%9lu\n",(unsigned long) records);
  printf("d0\t%9lu\n",(unsigned long) d0);
  printf("d1\t%9lu\n",(unsigned long) d1);
  printf("d2\t%9lu\n",(unsigned long) d2);
  printf("d3\t%9lu\n",(unsigned long) d3);
  printf("d4\t%9lu\n",(unsigned long) d4);
  printf("d5\t%9lu\n",(unsigned long) d5);
  printf("d6\t%9lu\n",(unsigned long) d6);
  printf("d7\t%9lu\n",(unsigned long) d7);
  printf("d8\t%9lu\n",(unsigned long) d8);
  printf("d9\t%9lu\n",(unsigned long) d9);
  printf(">9\t%9lu\n",(unsigned long) dfar);

  exit(0);
}
