use Config;

# Build cdb itself using whatever was defined for Perl.
open OUT, "> tmp" or
	die "$0: can't open tmp for output: $!\n";
print OUT "CC='$Config{cc} $Config{ccflags} $Config{cccdlflags} $Config{ccdlflags} $Config{optimize}'\n";
print OUT "LD='$Config{cc} $Config{ccflags} $Config{ldflags}'\n";
close OUT;
system 'sh ../../mv-if-diff tmp cdb-0.55/conf-cc.sh';

use ExtUtils::MakeMaker;

$cdbtargets = join ' ', map { "cdb-0.55/$_" } qw (
	*.o *.0 *.a
	12tocdbm cdbdump cdbget cdbmake cdbstats cdbtest compile
	find-systype load make-commands makelib systype uint32.h
);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'CDB_File',
	'VERSION_FROM'	=> 'CDB_File.pm',
	'MYEXTLIB'	=> 'libCDB_File$(LIB_EXT)',
	'clean'		=> { 'FILES' => $cdbtargets },
);

sub MY::postamble {
'
$(MYEXTLIB): cdb-0.55/conf-cc.sh
	cd cdb-0.55 && $(MAKE)
	cd cdb-0.55 && ./makelib ../$(MYEXTLIB) cdb_hash.o cdb_unpack.o cdb_seek.o \
	cdbmake_pack.o cdbmake_hash.o cdbmake_add.o
';
}
