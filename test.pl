# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN {print "1..32\n";}
END {print "not ok 1\n" unless $loaded;}
use CDB_File;
$loaded = 1;
print "ok 1\n";

# Test that attempt to tie to nonexist file fails.
#tie %h, CDB_File, 'nonesuch.cdb' and print 'not ';
print "ok 2\n";

# Test that attempt to read incorrect file fails.
open OUT, '> bad.cdb'; close OUT;
tie %h, CDB_File, 'bad.cdb' or print 'not ';
print "ok 3\n";

eval { print $h{'one'} };
print 'not ' unless $@ =~ /^Read of CDB_File failed:/;
print "ok 4\n";

untie %h;
unlink 'bad.cdb';

# Test that file can be created.
%a = qw(one Hello two Goodbye);
eval { CDB_File::create %a, 'good.cdb', 'good.tmp' or print 'not ' };
print "$@ not " if $@;
print "ok 5\n";

($d, $i, $mode, $l, $u, $g, $r, $s, $a, $m, $c, $b, $n) = stat 'good.cdb';
# Hmm... really should use S_IRUSR and friends here.
$mode & 0222 and print 'not ';
print "ok 6\n";

# Test that good file works.
tie %h, CDB_File, 'good.cdb' or print 'not ';
print "ok 7\n";

($t = tied %h) =~ /^CDB_File=SCALAR/ or print 'not ';
print "ok 8\n";

$h{'one'} eq 'Hello' or print 'not ';
print "ok 9\n";

defined $h{'1'} and print 'not ';
print "ok 10\n";

exists $h{'two'} or print 'not ';
print "ok 11\n";

exists $h{'three'} and print 'not ';
print "ok 12\n";

@h = sort keys %h;
@h == 2 and $h[0] eq 'one' and $h[1] eq 'two' or print 'not ';
print "ok 13\n";

eval { $h{'four'} = 'foo' };
print 'not ' unless $@ =~ /Modification of a CDB_File attempted/;
print "ok 14\n";

eval { delete $h{'five'} };
print 'not ' unless $@ =~ /Modification of a CDB_File attempted/;
print "ok 15\n";

unlink 'good.cdb';

# Test empty file.
undef %a;
eval { CDB_File::create %a, 'empty.cdb', 'empty.tmp' or print 'not ' };
print "$@ not " if $@;
print "ok 16\n";

tie %h, CDB_File, 'empty.cdb' or print 'not ';
print "ok 17\n";

keys %h == 0 or print 'not ';
print "ok 18\n";

unlink 'empty.cdb';

# Test failing new.
new CDB_File '.', 'cdb-0.55' and print 'not ';
print "ok 19\n";

# Test file with repeated keys.
$tmp = 'repeat.tmp';
$cdbm = new CDB_File 'repeat.cdb', $tmp or print 'not ';
print "ok 20\n";

$cdbm->insert('dog', 'perro');
$cdbm->insert('cat', 'gato');
$cdbm->insert('cat', 'chat');
$cdbm->insert('dog', 'chien');
$cdbm->insert('rabbit', 'conejo');

$tmp = 'ERROR!'; # Test that name was stashed correctly.

$cdbm->finish;

$t = tie %h, CDB_File, 'repeat.cdb' or print 'not ';
print "ok 21\n";

# Test that NEXTKEY can't be used immediately after TIEHASH.
eval { $t->NEXTKEY('dog') };
print 'not ' unless $@ =~ /^Use CDB_File::FIRSTKEY before CDB_File::NEXTKEY/;
print "ok 22\n";

@k = keys %h; @v = values %h;
$k[0] eq 'dog' and $k[1] eq 'cat' and $k[2] eq 'cat' and $k[3] eq 'dog' and $k[4] eq 'rabbit' and
	$v[0] eq 'perro' and $v[1] eq 'gato' and $v[2] eq 'chat' and $v[3] eq 'chien' and $v[4] eq 'conejo' or
	print 'not ';
print "ok 23\n";

$v = $t->multi_get('cat');
@$v == 2 and $$v[0] eq 'gato' and $$v[1] eq 'chat' or print 'not ';
print "ok 24\n";

$v = $t->multi_get('dog');
@$v == 1 and $$v[0] eq 'perro' or print 'not ';
print "ok 25\n";

$v = $t->multi_get('foo');
defined @$v and print 'not ';
print "ok 26\n";

# Test undefined keys.
{
	local $SIG{__WARN__} = sub { $warned = 1 if $_[0] =~ /^Use of uninitialized value/ };
	local $^W = 1;

	$warned = 0; 
	$x = undef;
	not defined $h{$x} and $warned or print 'not ';
	print "ok 27\n";

	$warned = 0;
	not exists $h{$x} and $warned or print 'not ';
	print "ok 28\n";

	$warned = 0;
	$v = $t->multi_get('rabbit') and not $warned or print 'not ';
	print "ok 29\n";
}

# Check that object is readonly.
eval { $$t = 'foo' };
$@ =~ /^Modification of a read-only value/ and $h{'cat'} eq 'gato' or print 'not ';
print "ok 30\n";

unlink 'repeat.cdb';

# Regression test - dumps core in 0.6.
%a = ('one', '');
CDB_File::create %a, 'good.cdb', 'good.tmp' or print "not ";
tie %h, CDB_File, 'good.cdb' or print "not ";
print "not " if $h{'zero'} or $h{'one'};
print "ok 31\n";

# And here's one I introduced while fixing 31 :-(.
defined $h{'one'} or print "not ";
print "ok 32\n";

unlink 'good.cdb';
