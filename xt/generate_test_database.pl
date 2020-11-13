#!perl

use strict;
use warnings;

use blib;
use CDB_File ();

open( my $urand_fh, '<', '/dev/urandom' ) or die("Need /dev/urandom to run this utility");

$CDB_File::VERSION eq '0.96' or die("This utility is meant to generate a CDB File on 0.96. You need to have that installed");

my $file = 'xt/compatibility.cdb';

my $utf8_key   = '“Copyright © ”';
my $utf8_value = '“Trademark ™ ”';

my $cdb_ver = $CDB_File::VERSION;

unlink $file;
my $cdb = CDB_File->new( $file, "$file.$$" ) or die $!;
$cdb->insert( $utf8_key, $utf8_value );
foreach my $step ( 1 .. 300 ) {
    my $key   = rnd_str();
    my $value = rnd_str();

    # Inject a few values with an empty string.
    $value = '' if ( $step % 20 == 0 );

    $cdb->insert( $key, $value );
}

$cdb->insert( '', 'empty' );
$cdb->finish;

sub rnd_str {
    my $len = int( rand(10) ) + 1;
    my $buffer;
    read( $urand_fh, $buffer, $len );

    return $buffer;
}
