/*

Don't tell the OO Police, but...

There are actually two different objects called CDB_File.  One is
created by TIEHASH, and accessed by the usual tied hash methods (FETCH,
FIRSTKEY, etc.).  The other is created by new, and accessed by insert
and finish.

In both cases, the object is a blessed reference to a scalar.  The
scalar contains either a struct cdbobj or a struct cdbmakeobj.

It gets a little messy in DESTROY: since this method will automatically
be called for both sorts of object, it distinguishes them by their
different sizes.

*/

#ifdef __cplusplus
extern "C" {
#endif

#define PERLIO_NOT_STDIO 0

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "cdb-0.55/cdb.h"
#include "cdb-0.55/cdbmake.h"

#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

#ifdef __cplusplus
}
#endif

struct cdbobj {
	int fd;        /* The file descriptor. */
	uint32 end;    /* If non zero, the file offset of the first byte of hash tables. */
	SV *curkey;    /* While iterating: a copy of the current key; */
	uint32 curpos; /*                  the file offset of the current record; */
	uint32 curlen; /*                  the length of the current data item. */
};

struct cdbmakeobj {
	FILE *fi;            /* Handle of FILE being created. */
	char *fn;            /* Final name of file. */
	char *fntemp;        /* Temporary name of file. */
	uint32 pos;          /* The current file offset. */
	struct cdbmake cdbm; /* Stores pointer information, etc. */
};

static void writeerror() { croak("Write to CDB_File failed: %s", Strerror(errno)); }

static void readerror() { croak("Read of CDB_File failed: %s", Strerror(errno)); }

static void seekerror() { croak("Seek in CDB_File failed: %s", Strerror(errno)); }

static void nomem() { croak("Out of memory!"); }

static void format() { croak("Bad CDB_File format\n"); }

static uint32 safeadd(u, v) uint32 u; uint32 v; {
	u += v;
	if (u < v) croak("CDB database too large\n");
	return u;
}

static uint32 findend(fd) int fd; {
	char buf[4];

	if (lseek(fd, 0, SEEK_SET) != 0) readerror();
	if (cdb_bread(fd, buf, 4) == -1) readerror();
	return cdb_unpack(buf);
}

MODULE = CDB_File		PACKAGE = CDB_File	PREFIX = cdb_

SV *
cdb_TIEHASH(dbtype, filename)
	char *		dbtype
	char *		filename

	PROTOTYPE: $$

	CODE:
	struct cdbobj cdb;
	SV *cdbp;

	if ((cdb.fd = open(filename, O_RDONLY)) == -1) XSRETURN_NO;
	cdb.end = 0;
	/* Copy cdb into a SV.  Potential problem: the alignment of the
	 * SV may be wrong, leading to bus errors later when we use the
	 * cdbobj.  Assume that everything comes from malloc(), so is
	 * ok.
	 */
	cdbp = newSVpv((char *)&cdb, sizeof(struct cdbobj));
	/* For backwards compatability with 5.002, don't use
	 * RETVAL = newRV_noinc(...);
	 */
	RETVAL = newRV(cdbp);
	SvREFCNT_dec(cdbp);
	sv_bless(RETVAL, gv_stashpv(dbtype, 0));
	/* Prevent the user stomping on the cdbobj. */
	SvREADONLY_on(cdbp);

	OUTPUT:
		RETVAL

SV *
cdb_FETCH(db, key)
	SV *		db
	SV *		key

	PROTOTYPE: $$

	CODE:
	struct cdbobj *this;
	uint32 dlen;
	int fd, found;
	off_t pos;

	if (!SvOK(key)) {
		if (dowarn) warn(warn_uninit);
		XSRETURN_UNDEF;
	}
	this = (struct cdbobj *)SvPV(SvRV(db), na);
	fd = this->fd; /* This micro optimization makes a measurable difference. */
	if (this->end && sv_eq(this->curkey, key)) {
		pos = this->curpos + 8 + SvCUR(key);
		if (lseek(fd, pos, SEEK_SET) != pos) seekerror();
		dlen = this->curlen;
		found = 1;
	} else {
		found = cdb_seek(fd, SvPV(key, na), SvCUR(key), &dlen);
		if ((found != 0) && (found != 1)) readerror();
	}
	ST(0) = sv_newmortal();
	if (found && sv_upgrade(ST(0), SVt_PV)) {
		(void)SvPOK_only(ST(0));
		SvGROW(ST(0), dlen + 1); SvCUR_set(ST(0), dlen);
		if (cdb_bread(fd, SvPVX(ST(0)), dlen) == -1) readerror();
		SvPV(ST(0), na)[dlen] = '\0';
	}

int
cdb_EXISTS(db, key)
	SV *		db
	SV *		key

	PROTOTYPE: $$

	CODE:
	struct cdbobj *this;
	uint32 dlen;

	if (!SvOK(key)) {
		if (dowarn) warn(warn_uninit);
		XSRETURN_NO;
	}
	this = (struct cdbobj *)SvPV(SvRV(db), na);
	RETVAL = cdb_seek(this->fd, SvPV(key, na), SvCUR(key), &dlen);
	if (RETVAL != 0 && RETVAL != 1) readerror();

	OUTPUT:
		RETVAL

void
cdb_DESTROY(db)
	SV *		db

	PROTOTYPE: $

	CODE:
	struct cdbobj *this;

	if (SvCUR(SvRV(db)) == sizeof(struct cdbobj)) { /* It came from TIEHASH. */
		this = (struct cdbobj *)SvPV(SvRV(db), na);
		/* I don't believe it's possible for close() on an
		 * O_RDONLY file to fail, so the return value isn't
		 * checked.
		 */
		close(this->fd);
	}

SV *
cdb_FIRSTKEY(db)
	SV *		db

	PROTOTYPE: $

	CODE:
	struct cdbobj *this;
	char buf[8];
	uint32 dlen, klen;

	this = (struct cdbobj *)SvPV(SvRV(db), na);
	if (this->end == 0) this->end = findend(this->fd);
	ST(0) = sv_newmortal();
	if (this->end > 2048 && sv_upgrade(ST(0), SVt_PV)) { /* Database is not empty. */
		if (lseek(this->fd, 2048, 0) != 2048) seekerror();
		if (cdb_bread(this->fd, buf, 8) == -1) readerror();
		klen = cdb_unpack(buf); dlen = cdb_unpack(buf + 4);
		(void)SvPOK_only(ST(0));
		SvGROW(ST(0), klen); SvCUR_set(ST(0), klen);
		if (cdb_bread(this->fd, SvPVX(ST(0)), klen) == -1) readerror();
		this->curkey = newSVpv(SvPVX(ST(0)), klen);
		this->curpos = 2048;
		this->curlen = dlen;
	}

SV *
cdb_NEXTKEY(db, key)
	SV *		db
	SV *		key

	PROTOTYPE: $$

	CODE:
	struct cdbobj *this;
	char buf[8];
	int fd, found;
	off_t pos;
	uint32 dlen, klen;

	if (!SvOK(key)) {
		if (dowarn) warn(warn_uninit);
		XSRETURN_UNDEF;
	}
	this = (struct cdbobj *)SvPV(SvRV(db), na);
	fd = this->fd;
	if (this->end == 0) croak("Use CDB_File::FIRSTKEY before CDB_File::NEXTKEY");
	if (sv_eq(this->curkey, key)) {
		if (lseek(fd, this->curpos, SEEK_SET) == -1) seekerror();
		if (cdb_bread(fd, buf, 8) == -1) readerror();
		klen = cdb_unpack(buf); dlen = cdb_unpack(buf + 4);
		if ((pos = lseek(fd, klen + dlen, SEEK_CUR)) == -1) seekerror();
		found = 1;
	} else {
		found = cdb_seek(fd, SvPV(key, na), SvCUR(key), &dlen);
		if (found != 0 && found != 1) readerror();
		if (found)
			if ((pos = lseek(fd, dlen, SEEK_CUR)) < 0) readerror();
	}
	ST(0) = sv_newmortal();
	if (found && (pos < this->end) && sv_upgrade(ST(0), SVt_PV)) {
		if (cdb_bread(fd, buf, 8) == -1) readerror();
		klen = cdb_unpack(buf); dlen = cdb_unpack(buf + 4);
		(void)SvPOK_only(ST(0));
		SvGROW(ST(0), klen); SvCUR_set(ST(0), klen);
		if (cdb_bread(fd, SvPVX(ST(0)), klen) == -1) readerror();
		this->curpos = pos;
		this->curlen = dlen;
		sv_setpvn(this->curkey, SvPVX(ST(0)), klen);
	} else {
		sv_setsv(this->curkey, &sv_undef);
	}

SV *
cdb_new(this, fn, fntemp)
	char *		this
	char *		fn
	char *		fntemp

	PROTOTYPE: $$$

	CODE:
	SV *cdbmp;
	struct cdbmakeobj cdbmake;
	int i;
	mode_t oldum;

	cdbmake_init(&cdbmake.cdbm);

	oldum = umask(0222);
	cdbmake.fi = fopen(fntemp, "w");
	umask(oldum);
	if (!cdbmake.fi) XSRETURN_UNDEF;

	for (i = 0; i < sizeof(cdbmake.cdbm.final); ++i)
		if (putc(' ', cdbmake.fi) == EOF)
			writeerror();

	cdbmake.pos = sizeof(cdbmake.cdbm.final); 

	/* Oh, for referential transparency. */
	New(0, cdbmake.fn, strlen(fn) + 1, char);
	New(0, cdbmake.fntemp, strlen(fntemp) + 1, char);
	strncpy(cdbmake.fn, fn, strlen(fn) + 1);
	strncpy(cdbmake.fntemp, fntemp, strlen(fntemp) + 1);

	cdbmp = newSVpv((char *)&cdbmake, sizeof(struct cdbmakeobj));
	RETVAL = newRV(cdbmp);
	SvREFCNT_dec(cdbmp);
	sv_bless(RETVAL, gv_stashpv(this, 0));

	OUTPUT:
		RETVAL

void
cdb_insert(cdbmake, k, v)
	SV *		cdbmake
	SV *		k
	SV *		v

	PROTOTYPE: $$$

	CODE:
	char packbuf[8];
	int c, i, klen, vlen;
	struct cdbmakeobj *this;
	uint32 h;

	this = (struct cdbmakeobj *)SvPV(SvRV(cdbmake), na);
	klen = SvCUR(k); vlen = SvCUR(v);
	cdbmake_pack(packbuf, (uint32)klen);
	cdbmake_pack(packbuf + 4, (uint32)vlen);

	if (fwrite(packbuf, 1, 8, this->fi) < 8) writeerror();

	h = CDBMAKE_HASHSTART;
	for (i = 0; i < klen; ++i) {
		c = SvPV(k, na)[i];
		h = cdbmake_hashadd(h, c);
		if (putc(c, this->fi) == EOF) writeerror();
	}
	if (fwrite(SvPV(v, na), 1, vlen, this->fi) < vlen) writeerror();

	if (!cdbmake_add(&this->cdbm, h, this->pos, malloc)) nomem();
	this->pos = safeadd(this->pos, (uint32) 8);
	this->pos = safeadd(this->pos, (uint32) klen);
	this->pos = safeadd(this->pos, (uint32) vlen);


int
cdb_finish(cdbmake)
	SV *		cdbmake;

	PROTOTYPE: $

	CODE:
	char packbuf[8];
	int i;
	struct cdbmakeobj *this;
	uint32 len, u;

	this = (struct cdbmakeobj *)SvPV(SvRV(cdbmake), na);

	if (!cdbmake_split(&this->cdbm, malloc)) nomem();

	for (i = 0; i < 256; ++i) {
		len = cdbmake_throw(&this->cdbm, this->pos, i);
		for (u = 0; u < len; ++u) {
			cdbmake_pack(packbuf, this->cdbm.hash[u].h);
			cdbmake_pack(packbuf + 4, this->cdbm.hash[u].p);
			if (fwrite(packbuf, 1, 8, this->fi) < 8) writeerror();
			this->pos = safeadd(this->pos, (uint32) 8);
		}
	}

	if (fflush(this->fi) == EOF) writeerror();
	rewind(this->fi);

	if (fwrite(this->cdbm.final, 1, sizeof(this->cdbm.final), this->fi) < sizeof(this->cdbm.final)) writeerror();
	if (fflush(this->fi) == EOF) writeerror();

	if (fsync(fileno(this->fi)) == -1) XSRETURN_NO;
	if (fclose(this->fi) == EOF) XSRETURN_NO;

	if (rename(this->fntemp, this->fn)) XSRETURN_NO;
	
	Safefree(this->fn);
	Safefree(this->fntemp);

	RETVAL = 1;

	OUTPUT:
		RETVAL
