#!perl

use strict;
use warnings;

use Test::More;

plan( skip_all => "utf8 macro support requires > 5.13.7" ) if $] < '5.013007';
plan tests => 5;

use CDB_File;
use File::Temp;

my ( $db, $db_tmp ) = get_db_file_pair(1);

# He breaks everyone else's database, let's make sure he doesn't break ours :P
my $avar = my $latin_avar = "\306var";
utf8::upgrade($avar);

# Dang accents!
my $leon = "L\350on";
utf8::upgrade($leon);

my %a = qw(one Hello two Goodbye);
$a{$avar} = $leon;
eval { CDB_File::create( %a, $db->filename, $db->filename, 'utf8' => 1 ) or die "Failed to create cdb: $!" };
is( "$@", '', "Create cdb" );

my %h;

# Test that good file works.
tie( %h, "CDB_File", $db->filename, 'utf8' => 1 ) and pass("Test that good file works");
is $h{$avar},       $leon, "Access a utf8 key";
is $h{$latin_avar}, $leon, "Access a utf8 key using its latin1 record.";
is( utf8::is_utf8($latin_avar), '', "\$latin_avar is not converted to utf8" );

done_testing();
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
