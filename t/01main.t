use strict;
use Test;
plan tests => 112;
$|++;
eval "use CDB_File";
ok(!$@);

my %h;
tie(%h, "CDB_File", 'nonesuch.cdb') or ok(1, 1, "Tie non-existant file");

open OUT, '> bad.cdb'; close OUT;
tie(%h, "CDB_File", 'bad.cdb') and ok(1, 1, "Load blank cdb file (invalid file, but loading it works)");

eval { print $h{'one'} };
ok($@, qr/^Read of CDB_File failed:/, "Test that attempt to read incorrect file fails");

untie %h;
unlink 'bad.cdb';

my %a = qw(one Hello two Goodbye);
eval { CDB_File::create(\%a, 'good.cdb', 'good.tmp') || die "Failed to create cdb: $!" };
ok("$@", '', "Create cdb");

# Test that good file works.
tie(%h, "CDB_File", 'good.cdb') and ok(1, 1, "Test that good file works");

my $t = tied %h;
ok($t);
ok($t->FETCH('one'), 'Hello', "Test that good file FETCHes right results");

ok($h{'one'}, 'Hello', "Test that good file hash access gets right results");

ok(!defined($h{'1'}), 1, "Check defined() non-existant entry works");

ok(exists($h{'two'}), 1, "Check exists() on a real entry works");

ok(!exists($h{'three'}), 1, "Check exists() on non-existant entry works");

# Test low level access.
my $fh = $t->handle;
my $x;

exists($h{'one'}); # go to this entry
print "# Datapos: ", $t->datapos, ", Datalen: ", $t->datalen, "\n";
sysseek($fh, $t->datapos, 0);
sysread($fh, $x, $t->datalen);
ok($x, 'Hello', "Check low level access read worked");

exists($h{'two'});
print "# Datapos: ", $t->datapos, ", Datalen: ", $t->datalen, "\n";
sysseek($fh, $t->datapos, 0);
sysread($fh, $x, $t->datalen);
ok($x, 'Goodbye', "Check low level access read worked");

exists($h{'three'});
print "# Datapos: ", $t->datapos, ", Datalen: ", $t->datalen, "\n";
ok($t->datapos, 0, "Low level access on no-exist entry");
ok($t->datalen, 0, "Low level access on no-exist entry");

my @h = sort keys %h;
ok(@h, 2, "keys length == 2");
ok($h[0], 'one', "first key right");
ok($h[1], 'two', "second key right");

eval { $h{'four'} = 'foo' };
ok($@, qr/Modification of a CDB_File attempted/, "Check modifying throws exception");

eval { delete $h{'five'} };
ok($@, qr/Modification of a CDB_File attempted/, "Check modifying throws exception");

unlink 'good.cdb';

# Test empty file.
%a = ();
eval { CDB_File::create(\%a, 'empty.cdb', 'empty.tmp') || die "CDB create failed" };
ok(!$@, 1, "No errors creating cdb");

tie(%h, "CDB_File", 'empty.cdb') and ok(1, 1, "Tie new empty cdb");

@h = keys %h;
ok(@h, 0, "Empty cdb has no keys");

unlink 'empty.cdb';

# Test failing new.
ok(!CDB_File->new('..', '.'), 1, "Creating cdb with dirs fails");

# Test file with repeated keys.
my $tmp = 'repeat.tmp';
my $cdbm = CDB_File->new('repeat.cdb', $tmp);
ok($cdbm);

$cdbm->insert('dog', 'perro');
$cdbm->insert('cat', 'gato');
$cdbm->insert('cat', 'chat');
$cdbm->insert('dog', 'chien');
$cdbm->insert('rabbit', 'conejo');

$tmp = 'ERROR!'; # Test that name was stashed correctly.

$cdbm->finish;

$t = tie %h, "CDB_File", 'repeat.cdb';
ok($t);

eval { $t->NEXTKEY('dog') };
# ok($@, qr/^Use CDB_File::FIRSTKEY before CDB_File::NEXTKEY/, "Test that NEXTKEY can't be used immediately after TIEHASH");
ok(!$@, 1, "Test that NEXTKEY can be used immediately after TIEHASH");

# Check keys/values works
my @k = keys %h;
my @v = values %h;
ok($k[0], 'dog');     ok($v[0], 'perro');
ok($k[1], 'cat');     ok($v[1], 'gato');
ok($k[2], 'cat');     ok($v[2], 'chat');
ok($k[3], 'dog');     ok($v[3], 'chien');
ok($k[4], 'rabbit');  ok($v[4], 'conejo');

@k = ();
@v = ();

# Check each works
while (my ($k, $v) = each %h) {
    push @k, $k;
    push @v, $v;
}
ok($k[0], 'dog');     ok($v[0], 'perro');
ok($k[1], 'cat');     ok($v[1], 'gato');
ok($k[2], 'cat');     ok($v[2], 'chat');
ok($k[3], 'dog');     ok($v[3], 'chien');
ok($k[4], 'rabbit');  ok($v[4], 'conejo');

my $v = $t->multi_get('cat');
ok(@$v, 2, "multi_get returned 2 entries");
ok($v->[0], 'gato');
ok($v->[1], 'chat');

$v = $t->multi_get('dog');
ok(@$v, 2, "multi_get returned 2 entries");
ok($v->[0], 'perro');
ok($v->[1], 'chien');

$v = $t->multi_get('rabbit');
ok(@$v, 1, "multi_get returned 1 entry");
ok($v->[0], 'conejo');

$v = $t->multi_get('foo');
ok(ref($v), 'ARRAY', "multi_get on non-existant entry works");
ok(@$v, 0);

while (my ($k, $v) = each %h) {
    $v = $t->multi_get($k);
    ok($v->[0] eq 'gato' and $v->[1] eq 'chat') if $k eq 'cat';
    ok($v->[0] eq 'perro' and $v->[1] eq 'chien') if $k eq 'dog';
    ok($v->[0] eq 'conejo') if $k eq 'rabbit';
}

# Test undefined keys.
{
    my $warned = 0;
    local $SIG{__WARN__} = sub { $warned = 1 if $_[0] =~ /^Use of uninitialized value/ };
    local $^W = 1;
    
    my $x;
    ok(not defined $h{$x});
    ok($warned);
        
    $warned = 0;
    ok(not exists $h{$x});
    ok($warned);
    
    $warned = 0;
    my $v = $t->multi_get('rabbit');
    ok($v);
    ok(not $warned);
}

# Check that object is readonly.
eval { $$t = 'foo' };
ok($@, qr/^Modification of a read-only value/, "Check object (\$t) is read only");
ok($h{'cat'}, 'gato');

unlink 'repeat.cdb';

# Regression test - dumps core in 0.6.
%a = ('one', '');
ok(CDB_File::create(\%a, 'good.cdb', 'good.tmp'));
ok(tie(%h, "CDB_File", 'good.cdb'));
ok(!( $h{'zero'} or $h{'one'} ));

# And here's one I introduced while fixing the one above
ok(defined($h{'one'}));

unlink 'good.cdb';

# Test numeric data (broken before 0.8)
my $h = CDB_File->new('t.cdb', 't.tmp');
ok($h);
$h->insert(1, 1 * 23);
ok($h->finish);
ok(tie(%h, "CDB_File", 't.cdb'));
ok($h{1} == 23, 1, "Numeric comparison works");
untie %h;

unlink 't.cdb';

# Test zero value with multi_get (broken before 0.85)
$h = CDB_File->new('t.cdb', 't.tmp');
ok($h);
$h->insert('x', 0);
$h->insert('x', 1);
ok($h->finish);
ok($t = tie(%h, "CDB_File", 't.cdb'));
$x = $t->multi_get('x');
ok(@$x, 2);
ok($x->[0] == 0);
ok($x->[1] == 1);

unlink 't.cdb';

$h = CDB_File->new('t.cdb', 't.tmp');
ok($h);
for (my $i = 0; $i < 10; ++$i) {
    $h->insert($i, $i);
}
ok($h->finish);
ok($t = tie(%h, "CDB_File", 't.cdb'));
for (my $i = 0; $i < 10; ++$i) {
    my ($k, $v) = each %h;
    if ($k == 2) {
        ok(exists($h{4}));
    }
    if ($k == 5) {
        ok(!exists($h{23}));
    }
    if ($k == 7) {
        my $m = $t->multi_get(3);
        ok(@$m, 1);
        ok($m->[0], 3);
    }
    ok($k, $i);
    ok($v, $i);
}

unlink 't.cdb';
