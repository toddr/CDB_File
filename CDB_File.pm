package CDB_File;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT_OK);

use DynaLoader ();
use Exporter ();

@ISA = qw(DynaLoader Exporter);
@EXPORT_OK = qw(create);

$VERSION = '0.04';

bootstrap CDB_File $VERSION;

# Preloaded methods go here.

sub CLEAR {
	croak "Modification of a CDB_File attempted"
}

sub DELETE {
	&CLEAR
}

sub STORE {
	&CLEAR
}

1;

__END__

=head1 NAME

CDB_File - Perl extension for access to CDB 

=head1 SYNOPSIS

    use CDB_File;
    tie %h, 'CDB_File', 'file.cdb' or die "tie failed: $!\n";

    CDB_File::create %t, 't.cdb', 't.tmp';

=head1 DESCRIPTION

B<CDB_File> is a module which provides a Perl interface to Dan
Berstein's B<cdb> package:

    cdb is a fast, reliable, lightweight package for creating and
    reading constant databases.

After the C<tie> shown above, accesses to C<%h> will refer
to the B<cdb> file C<file.cdb>, as described in L<perlfunc/tie>.

C<CDB_File::create %t, $file, $tmp> creates a B<cdb> file named C<$file>
containing the contents of C<%t>.  C<$tmp> must refer to a temporary
file which can be atomically renamed to C<$file>.  C<CDB_File::create>
may be imported.

=head1 EXAMPLES

1. Convert a Berkeley DB (B-tree) database to CDB format.

    use CDB_File;
    use DB_File;

    tie %h, DB_File, $ARGV[0], O_RDONLY, undef, $DB_BTREE or
            die "$0: can't tie to $ARGV[0]: $!\n";

    CDB_File::create %h, $ARGV[1], "$ARGV[1].tmp" or
            die "$0: can't create cdb: $!\n";

2. Convert a flat file to CDB format.  In this example, the flat file
consists of one key per line, separated by a colon from the value.
Blank lines and lines beginning with B<#> are skipped.  The flat file
may contain repeated keys: in this case the different values are
joined with C<$;>.

    use CDB_File;
    while (<>) {
            next if /^$/ or /^#/;
            chop;
            ($k, $v) = split /:/, $_, 2;
            if ($data{$k}) {
                    $data{$k} .= "$;$v";
            } else {
                    $data{$k} = "$v";
            }
    }
    CDB_File::create %data, 'data.cdb', 'data.tmp' or
            die "$0: cdb create failed\n";

3. Use the CDB file created in example 2.

    tie %data, 'CDB_File', 'data.cdb' or
            die "$0: can't tie to data.cdb: $!\n";
    my $values = $data{$key};
    if (defined $values) {
            foreach (split /$;/, $values) {
                    # Do that funky thang...
            }
    } else {
            warn "$0: can't find `$key'\n";
    }

4. Perl version of cdbdump.

    tie %data, 'CDB_File', $ARGV[0] or
            die "$0: can't tie to $ARGV[0]: $!\n";
    while (($k, $v) = each %data) {
            print '+', length $k, ',', length $v, ":$k->$v\n";
    }
    print "\n";

=head1 DIAGNOSTICS

=over 4

=item Modification of a CDB_File attempted

This fatal error will result from any attempt to modify a hash tied to a
B<CDB_File>.

=back

=head1 BUGS

It ain't lightweight after you've plumbed Perl into it.

The Perl interface to B<cdb> imposes the restriction that data must fit
into memory.

=head1 SEE ALSO

cdb(3).

=head1 AUTHOR

Tim Goodwin, <tim@uunet.pipex.com>, 1997-01-08.

=cut
