default: it

cdb.0: \
cdb.3
	nroff -man cdb.3 > cdb.0

cdb_hash.o: \
compile cdb_hash.c cdb.h uint32.h cdb.h cdb_hash.c
	./compile cdb_hash.c

cdb_seek.o: \
compile cdb_seek.c cdb_seek.c cdb_seek.c cdb.h uint32.h cdb.h \
cdb_seek.c
	./compile cdb_seek.c

cdb_unpack.o: \
compile cdb_unpack.c cdb.h uint32.h cdb.h cdb_unpack.c
	./compile cdb_unpack.c

cdbdump: \
load cdbdump.o libcdb.a
	./load cdbdump libcdb.a

cdbdump.0: \
cdbdump.1
	nroff -man cdbdump.1 > cdbdump.0

cdbdump.o: \
compile cdbdump.c cdbdump.c cdb.h uint32.h cdb.h cdbdump.c
	./compile cdbdump.c

cdbget: \
load cdbget.o libcdb.a
	./load cdbget libcdb.a

cdbget.0: \
cdbget.1
	nroff -man cdbget.1 > cdbget.0

cdbget.o: \
compile cdbget.c cdbget.c cdb.h uint32.h cdb.h cdbget.c
	./compile cdbget.c

cdbmake: \
load cdbmake.o libcdbmake.a
	./load cdbmake libcdbmake.a

cdbmake.0: \
cdbmake.1
	nroff -man cdbmake.1 > cdbmake.0

cdbmake.o: \
compile cdbmake.c cdbmake.c cdbmake.h uint32.h cdbmake.h cdbmake.c
	./compile cdbmake.c

cdbmake_add.o: \
compile cdbmake_add.c cdbmake.h uint32.h cdbmake.h cdbmake_add.c
	./compile cdbmake_add.c

cdbmake_hash.o: \
compile cdbmake_hash.c cdbmake.h uint32.h cdbmake.h cdbmake_hash.c
	./compile cdbmake_hash.c

cdbmake_pack.o: \
compile cdbmake_pack.c cdbmake.h uint32.h cdbmake.h cdbmake_pack.c
	./compile cdbmake_pack.c

cdbstats: \
load cdbstats.o libcdb.a
	./load cdbstats libcdb.a

cdbstats.0: \
cdbstats.1
	nroff -man cdbstats.1 > cdbstats.0

cdbstats.o: \
compile cdbstats.c cdbstats.c cdb.h uint32.h cdb.h cdbstats.c
	./compile cdbstats.c

cdbtest: \
load cdbtest.o libcdb.a
	./load cdbtest libcdb.a

cdbtest.0: \
cdbtest.1
	nroff -man cdbtest.1 > cdbtest.0

cdbtest.o: \
compile cdbtest.c cdbtest.c cdb.h uint32.h cdb.h cdbtest.c
	./compile cdbtest.c

12tocdbm: \
12tocdbm.sh warn-auto.sh
	cat warn-auto.sh 12tocdbm.sh > 12tocdbm
	chmod 755 12tocdbm

compile: \
make-commands systype
	./make-commands "`cat ./systype`" compile > compile
	chmod 755 compile

find-systype: \
find-systype.sh conf-cc.sh warn-auto.sh
	cat warn-auto.sh conf-cc.sh find-systype.sh > find-systype
	chmod 755 find-systype

it: \
cdbget cdbmake cdbdump cdbstats cdbtest 12tocdbm \
cdbget.0 cdbmake.0 cdbdump.0 cdbstats.0 cdbtest.0 cdb.0

libcdb.a: \
makelib cdb_hash.o cdb_unpack.o cdb_seek.o
	./makelib libcdb.a cdb_hash.o cdb_unpack.o cdb_seek.o

libcdbmake.a: \
makelib cdbmake_pack.o cdbmake_hash.o cdbmake_add.o
	./makelib libcdbmake.a cdbmake_pack.o cdbmake_hash.o \
	cdbmake_add.o

load: \
make-commands systype
	./make-commands "`cat ./systype`" load > load
	chmod 755 load

make-commands: \
make-cmds.sh conf-cc.sh warn-auto.sh
	cat warn-auto.sh conf-cc.sh make-cmds.sh > make-commands
	chmod 755 make-commands

makelib: \
make-commands systype
	./make-commands "`cat ./systype`" makelib > makelib
	chmod 755 makelib

shar: \
FILES BLURB README INSTALL TODO CHANGES FILES Makefile cdbget.1 \
cdbget.c cdbmake.1 cdbmake.c cdbdump.1 cdbdump.c cdbstats.1 \
cdbstats.c cdb.h cdb_hash.c cdb_unpack.c cdb_seek.c cdbmake.h \
cdbmake_pack.c cdbmake_hash.c cdbmake_add.c conf-cc.sh \
find-systype.sh make-cmds.sh trycpp.c warn-auto.sh uint32.h1 \
uint32.h2 tryulong32.c
	shar -m `cat FILES` > shar
	chmod 400 shar

systype: \
find-systype trycpp.c
	./find-systype > systype

uint32.h: \
tryulong32.c compile load uint32.h1 uint32.h2
	( ( ./compile tryulong32.c && ./load tryulong32 && \
	./tryulong32 ) >/dev/null 2>&1 \
	&& cat uint32.h2 || cat uint32.h1 ) > uint32.h
	rm -f tryulong32.o tryulong32
