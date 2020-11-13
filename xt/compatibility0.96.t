#!perl

use strict;
use warnings;

use Test::More tests => 304;

use CDB_File ();

my $file = 'xt/compatibility.cdb';
our %cdb;
tie %cdb, "CDB_File", $file;

note "UTF8 test";
my $utf8_key   = '“Copyright © ”';
my $utf8_value = '“Trademark ™ ”';
is( $cdb{$utf8_key}, $utf8_value, "UTF8 key fetches." );

note "Random keys";
my @keys = keys %cdb;

my $empty_keys;
foreach my $key (@keys) {
    my $value = $cdb{$key};
    isnt( $value, undef, "Fetched key isn't undef" );
    $empty_keys++ if ( $value eq '' );
}

is( $empty_keys, 15, "15 of the keys were an empty string" );
