#!perl

use strict;
use warnings;

use blib;
use Dumbbench;
use File::Temp qw/tempfile/;

use CDB_File;
open( my $rand_fh, '<', '/dev/urandom' ) or die;

my ( undef, $temp_cdb_file ) = tempfile( UNLINK => 1 );

my $values = 10_000_000;
my @strings;

print "Generating Values.\n";
for ( 1 .. ( $values * 2 ) ) {
    my $buffer;
    read( $rand_fh, $buffer, 20 );
    push @strings, $buffer;
}
print "Benchmarking.\n";

sub insert_cdb {
    unlink $temp_cdb_file;
    my $cdb = CDB_File->new( $temp_cdb_file, "$temp_cdb_file.$$" ) or die;

    foreach my $value ( 0 .. ( $values - 1 ) ) {
        $cdb->insert( $strings[ $value * 2 ], $strings[ $value * 2 + 1 ] );
    }

    $cdb->finish;
    print `ls -lh $temp_cdb_file`;
}

my $bench = Dumbbench->new(
    target_rel_precision => 0.005,    # seek ~0.5%
    initial_runs         => 10,       # the higher the more reliable
    verbosity            => 2,
);

$bench->add_instances(
    Dumbbench::Instance::PerlSub->new( code => sub { insert_cdb(); } ),
);

$bench->run;
$bench->report;
