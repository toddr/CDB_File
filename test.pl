# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN {print "1..17\n";}
END {print "not ok 1\n" unless $loaded;}
use CDB_File;
$loaded = 1;
print "ok 1\n";

# Test that attempt to tie to nonexist file fails.
#tie %h, CDB_File, 'nonesuch.cdb' and print "not ";
print "ok 2\n";

# Test that attempt to read incorrect file fails.
open OUT, '> bad.cdb'; close OUT;
tie %h, CDB_File, 'bad.cdb' or print "not ";
print "ok 3\n";
unlink 'bad.cdb';

eval { print $h{'one'} };
print "not " unless $@ =~ /^Read of CDB_File failed:/;
print "ok 4\n";

# Test that file can be created.
%a = qw(one Hello two Goodbye);
eval { CDB_File::create %a, 'good.cdb', 'good.tmp' or print "not " };
print "$@ not " if $@;
print "ok 5\n";

# Test that good file works.
tie %h, CDB_File, 'good.cdb' or print "not ";
print "ok 6\n";

($t = tied %h) =~ /^CDB_File=ARRAY/ or print "not ";
print "ok 7\n";

$h{'one'} eq 'Hello' or print "not ";
print "ok 8\n";

defined $h{'1'} and print "not ";
print "ok 9\n";

exists $h{'two'} or print "not ";
print "ok 10\n";

exists $h{'three'} and print "not ";
print "ok 11\n";

@h = sort keys %h;
@h == 2 and $h[0] eq 'one' and $h[1] eq 'two' or print "not ";
print "ok 12\n";

eval { $h{'four'} = 'foo' };
print "not " unless $@ =~ /Modification of a CDB_File attempted/;
print "ok 13\n";

eval { delete $h{'five'} };
print "not " unless $@ =~ /Modification of a CDB_File attempted/;
print "ok 14\n";

unlink 'good.cdb';

# Test empty file.
undef %a;
eval { CDB_File::create %a, 'empty.cdb', 'empty.tmp' or print "not " };
print "$@ not " if $@;
print "ok 15\n";

tie %h, CDB_File, 'empty.cdb' or print "not ";
print "ok 16\n";

scalar(keys %h) == 0 or print "not ";
print "ok 17\n";

unlink 'emtpy.cdb';
