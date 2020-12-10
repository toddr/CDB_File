#!perl

use strict;
use warnings;

use Test::More;

plan tests => 5;

use CDB_File;
use File::Temp;

my ( $db, $db_tmp ) = get_db_file_pair(1);

# He breaks everyone else's database, let's make sure he doesn't break ours :P
my $avar = my $latin_avar = "\306var";
utf8::upgrade($avar);

# Dang accents!
my $leon = my $latin_leon = "L\350on";
my $leon_not_encoded_but_not_utf8 = "L\303\250on";
utf8::upgrade($leon);

my %a = qw(one Hello two Goodbye);
eval {
    my $t = CDB_File->new($db->filename, $db->filename, utf8 => 0 ) or die "Failed to create cdb: $!";
    $t->insert(%a);
    $t->insert($avar, $leon);
    $t->insert($latin_avar, 12345);
    $t->finish;
};
is( "$@", '', "Create cdb" );

my %h;

# Test that good file works.
tie( %h, "CDB_File", $db->filename, 'utf8' => 0 ) and pass("Test that good file works");
is $h{$avar},       $leon_not_encoded_but_not_utf8, "Access a utf8 key and get back the utf8 sequence but without the utf8 flag.";
is( utf8::is_utf8($h{$avar}), '', "\$latin_avar is does not have the utf8 flag on." );
is $h{$latin_avar}, 12345, "Access of the latin1 key is not normalized so we get the alternate value.";

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
