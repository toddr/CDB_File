/*
A CDB_File object is a blessed reference to an array.  The first element
of the array is the file descriptor returned when the CDB file was
open()ed.  The macro CDBfd retrieves this.

If defined, the second element is a pointer to the end of the data in
the CDB file.  Because this is only needed when iterating over the CDB,
it is set in FIRSTKEY.  The macro CDBeod retrieves it.
*/

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "cdb-0.55/cdb.h"
#include "cdb-0.55/cdbmake.h"

#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

#define CDBfd(cdb) (SvIV(*av_fetch((AV *)SvRV(cdb), 0, 0)))
#define CDBeod(cdb) (SvIV(*av_fetch((AV *)SvRV(cdb), 1, 0)))

static void writeerror() { croak("Write to CDB_File failed: %s", strerror(errno)); }

static void readerror() { croak("Read of CDB_File failed: %s", strerror(errno)); }

static void nomem() { croak("Out of memory!"); }

static void format() { croak("Bad CDB_File format\n"); }

static uint32 safeadd(u, v) uint32 u; uint32 v;
{
	u += v;
	if (u < v) croak("CDB database too large\n");;
	return u;
}

MODULE = CDB_File		PACKAGE = CDB_File	PREFIX = cdb_

SV *
cdb_TIEHASH(dbtype, filename)
	char *		dbtype
	char *		filename

	CODE:
	int fd;
	AV *cdb;

	if ((fd = open(filename, O_RDONLY)) >= 0) {
		cdb = newAV();
		av_push(cdb, newSViv(fd));
		/* For backwards compatability with 5.002, don't use
		 * RETVAL = newRV_noinc(pfd);
		 */
		RETVAL = newRV((SV *)cdb);
		SvREFCNT_dec((SV *)cdb);
		sv_bless(RETVAL, gv_stashpv("CDB_File", 0));
	} else {
		RETVAL = newSVsv(&sv_undef);
	}

	OUTPUT:
		RETVAL

SV *
cdb_FETCH(db, key)
	SV *		db
	SV *		key

	CODE:
	uint32 dlen;
	int fd;

	fd = CDBfd(db);
	switch (cdb_seek(fd, SvPV(key, na), SvCUR(key), &dlen)) {
	default:
		readerror();
	case 0:
		RETVAL = newSVsv(&sv_undef);
		break;
	case 1:
		RETVAL = newSVpv("", 0);
		SvGROW(RETVAL, dlen); SvCUR_set(RETVAL, dlen);
		if (read(fd, SvPV(RETVAL, na), dlen) != dlen) readerror();
	}

	OUTPUT:
		RETVAL

int
cdb_EXISTS(db, key)
	SV *		db
	SV *		key

	CODE:
	uint32 dlen;

	RETVAL = cdb_seek(CDBfd(db), SvPV(key, na), SvCUR(key), &dlen);
	if (RETVAL != 0 && RETVAL != 1) readerror();

	OUTPUT:
		RETVAL

int
cdb_DESTROY(db)
	SV *		db

	CODE:

	RETVAL = 1;
	/* Can close on an O_RDONLY file fail? */
	if (close(CDBfd(db)) != 0)
		RETVAL = 0;

	OUTPUT:
		RETVAL

SV *
cdb_FIRSTKEY(db)
	SV *		db

	CODE:
	char buf[8];
	int fd;
	uint32 klen;

	fd = CDBfd(db);
	if (av_len((AV *)SvRV(db)) < 1) {
		if (lseek(fd, 0, SEEK_SET) != 0) readerror();
		if (read(fd, buf, 4) < 4) readerror();
		av_push((AV *)SvRV(db), newSViv(cdb_unpack(buf)));
	}
	if (CDBeod(db) == 2048) /* an empty database: why not? */
		RETVAL = newSVsv(&sv_undef);
	else {
		if (lseek(fd, 2048, 0) != 2048) format();
		if (read(fd, buf, 8) < 8) readerror();
		klen = cdb_unpack(buf);
		RETVAL = newSVpv("", 0);
		SvGROW(RETVAL, klen); SvCUR_set(RETVAL, klen);
		if (read(fd, SvPV(RETVAL, na), klen) != klen) readerror();
	}

	OUTPUT:
		RETVAL

SV *
cdb_NEXTKEY(db, key)
	SV *		db
	SV *		key

	CODE:
	char buf[8];
	int fd;
	uint32 dlen, klen, pos;

	fd = CDBfd(db);
	switch (cdb_seek(fd, SvPV(key, na), SvCUR(key), &dlen)) {
	default:
		readerror();
	case 0: /* someone gave us a bogus key */
		RETVAL = newSVsv(&sv_undef);
		break;
	case 1:
		if ((pos = lseek(fd, dlen, SEEK_CUR)) < 0) readerror();
		if (pos >= CDBeod(db)) /* this is the end */
			RETVAL = newSVsv(&sv_undef);
		else {
			if (read(fd, buf, 8) < 8) readerror();
			klen = cdb_unpack(buf);
			RETVAL = newSVpv("", 0);
			SvGROW(RETVAL, klen); SvCUR_set(RETVAL, klen);
			if (read(fd, SvPV(RETVAL, na), klen) != klen) readerror();
		}
	}


	OUTPUT:
		RETVAL

int
cdb_create(RHhash, fn, fntemp)
	SV *		RHhash
	char *		fn
	char *		fntemp

	PROTOTYPE: \%$$

	CODE:
	char *key;
	I32 keylen;
	SV *data;
	struct cdbmake cdbm;
	uint32 pos;
	char packbuf[8];

	FILE *fi;
	uint32 h, len, u;
	int c, i;
	unsigned long datalen;

	RETVAL = 0;

	cdbmake_init(&cdbm);

	fi = fopen(fntemp, "w");
	if (!fi) croak("Can't open `%s': %s", fntemp, strerror(errno));

	for (i = 0; i < sizeof(cdbm.final); ++i)
		if (putc(' ', fi) == EOF)
			writeerror();

	pos = sizeof(cdbm.final);

	hv_iterinit((HV *)SvRV(RHhash));
	while (data = hv_iternextsv((HV *)SvRV(RHhash), &key, &keylen)) {
		datalen = SvCUR(data);
		cdbmake_pack(packbuf, (uint32) keylen);
		cdbmake_pack(packbuf + 4, (uint32) datalen);

		if (fwrite(packbuf, 1, 8, fi) < 8) writeerror();

		h = CDBMAKE_HASHSTART;
		for (i = 0; i < keylen; ++i) {
			c = key[i];
			h = cdbmake_hashadd(h, c);
			if (putc(c, fi) == EOF) writeerror();
		}
		if (fwrite(SvPV(data, na), 1, datalen, fi) < datalen) writeerror();

		if (!cdbmake_add(&cdbm, h, pos, malloc)) nomem();
		pos = safeadd(pos, (uint32) 8);
		pos = safeadd(pos, (uint32) keylen);
		pos = safeadd(pos, (uint32) datalen);
	}

	if (!cdbmake_split(&cdbm, malloc)) nomem();

	for (i = 0; i < 256; ++i) {
		len = cdbmake_throw(&cdbm, pos, i);
		for (u = 0; u < len; ++u) {
			cdbmake_pack(packbuf, cdbm.hash[u].h);
			cdbmake_pack(packbuf + 4, cdbm.hash[u].p);
			if (fwrite(packbuf, 1, 8, fi) < 8) writeerror();
			pos = safeadd(pos, (uint32) 8);
		}
	}

	if (fflush(fi) == EOF) writeerror();
	rewind(fi);

	if (fwrite(cdbm.final, 1, sizeof(cdbm.final), fi) < sizeof(cdbm.final)) writeerror();
	if (fflush(fi) == EOF) writeerror();

	if (fsync(fileno(fi)) == -1) croak("Can't fsync `%s': %s", fntemp, strerror(errno));
	if (close(fileno(fi)) == -1) croak("Can't close `%s': %s", fntemp, strerror(errno));

	if (rename(fntemp, fn)) croak("Can't rename `%s' to `%s': %s", fntemp, fn, strerror(errno));

	RETVAL = 1;

	OUTPUT:
		RETVAL
