use Test;
BEGIN { plan tests => 18 }
use CDB_File;
use strict;

$|++;

my $c = CDB_File->new('last.cdb', 'last.tmp');
ok($c);

for (1..10) {
    $c->insert("Key$_" => "Val$_");
}

ok($c->finish);

my %h;
tie(%h, "CDB_File", "last.cdb");

my $count = 0;

while (my ($k, $v) = each(%h)) {
    ok($k);
    ok($v);
    last if $count++ > 5;
}

tie(%h, "CDB_File", "last.cdb");

while (my ($k, $v) = each(%h)) {
    ok($k);
    ok($v);
    last if $count++ > 5;
}

END { unlink 'last.cdb' }
