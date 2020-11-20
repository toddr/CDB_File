use strict;
use warnings;

use File::Temp;
use Test::More tests => 4;
use CDB_File;

my ( $db, $db_tmp ) = get_db_file_pair(1);

my $c = CDB_File->new( $db->filename, $db->filename );
isa_ok( $c, 'CDB_File::Maker' );

for ( 1 .. 10 ) {
    $c->insert( "Key$_" => "Val$_" );
}

is( $c->finish, 1, "Finish writes out" );

my %h;
my $tie_obj = tie( %h, "CDB_File", $db->filename );
isa_ok( tied(%h), 'CDB_File' );
my $count = 0;

my %copy;
my $res;

for ( 0 .. 10 ) {
    $res  = $tie_obj->fetch_all();
    %copy = %h;
}

is_deeply( \%copy, $res, "fetch_all matches the tied fetch" );

exit;

sub get_db_file_pair {
    my $auto_close_del = shift;

    my $file = File::Temp->new( UNLINK => 1 );
    my $tmp  = File::Temp->new( UNLINK => 1 );

    if ($auto_close_del) {
        close $file;
        close $tmp;
        unlink $file->filename;
        unlink $file->filename;
    }

    return ( $file, $tmp );
}
