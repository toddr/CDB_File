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
	'MYEXTLIB'	=> 'cdb-0.55/libcdb$(LIB_EXT) cdb-0.55/libcdbmake$(LIB_EXT)',
	'clean'		=> { 'FILES' => $cdbtargets },
);

sub MY::postamble {
'
$(MYEXTLIB): cdb-0.55/Makefile
	cd cdb-0.55 && $(MAKE)
';
}
