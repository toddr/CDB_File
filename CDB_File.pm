package CDB_File;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT_OK);

use AutoLoader ();
use DynaLoader ();
use Exporter ();

@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(create);

$VERSION = '0.8';

=head1 NAME

CDB_File - Perl extension for access to cdb databases 

=head1 SYNOPSIS

    use CDB_File;
    tie %h, 'CDB_File', 'file.cdb' or die "tie failed: $!\n";

    $t = new CDB_File ('t.cdb', 't.tmp') or die ...;
    $t->insert('key', 'value');
    $t->finish;

    CDB_File::create %t, $file, "$file.$$";

or

    use CDB_File 'create';
    create %t, $file, "$file.$$";

=head1 DESCRIPTION

B<CDB_File> is a module which provides a Perl interface to Dan
Berstein's B<cdb> package:

    cdb is a fast, reliable, lightweight package for creating and
    reading constant databases.

After the C<tie> shown above, accesses to C<%h> will refer
to the B<cdb> file C<file.cdb>, as described in L<perlfunc/tie>.

A B<cdb> file is created in three steps.  First call C<new CDB_File
($final, $tmp)>, where C<$final> is the name of the database to be
created, and C<$tmp> is the name of a temporary file which can be
atomically renamed to C<$final>.  Secondly, call the C<insert> method
once for each (I<key>, I<value>) pair.  Finally, call the C<finish>
method to complete the creation and renaming of the B<cdb> file.

A simpler interface to B<cdb> file creation is provided by
C<CDB_File::create %t, $final, $tmp>.  This creates a B<cdb> file named
C<$final> containing the contents of C<%t>.  As before,  C<$tmp> must
name a temporary file which can be atomically renamed to C<$final>.
C<CDB_File::create> may be imported.

=head1 EXAMPLES

These are all complete programs.

1. Convert a Berkeley DB (B-tree) database to B<cdb> format.

    use CDB_File;
    use DB_File;

    tie %h, DB_File, $ARGV[0], O_RDONLY, undef, $DB_BTREE or
            die "$0: can't tie to $ARGV[0]: $!\n";

    CDB_File::create %h, $ARGV[1], "$ARGV[1].$$" or
            die "$0: can't create cdb: $!\n";

2. Convert a flat file to B<cdb> format.  In this example, the flat
file consists of one key per line, separated by a colon from the value.
Blank lines and lines beginning with B<#> are skipped.

    use CDB_File;

    $cdb = new CDB_File("data.cdb", "data.$$") or
            die "$0: new CDB_File failed: $!\n";
    while (<>) {
            next if /^$/ or /^#/;
            chop;
            ($k, $v) = split /:/, $_, 2;
            if (defined $v) {
                    $cdb->insert($k, $v);
            } else {
                    warn "bogus line: $_\n";
            }
    }
    $cdb->finish or die "$0: CDB_File finish failed: $!\n";

3. Perl version of B<cdbdump>.

    use CDB_File;

    tie %data, 'CDB_File', $ARGV[0] or
            die "$0: can't tie to $ARGV[0]: $!\n";
    while (($k, $v) = each %data) {
            print '+', length $k, ',', length $v, ":$k->$v\n";
    }
    print "\n";

4. Although a B<cdb> file is constant, you can simulate updating it
in Perl.  This is an expensive operation, as you have to create a
new database, and copy into it everything that's unchanged from the
old database.  (As compensation, the update does not affect database
readers.  The old database is available for them, till the moment the
new one is C<finish>ed.)

    use CDB_File;

    $file = 'data.cdb';
    $new = new CDB_File($file, "$file.$$") or
            die "$0: new CDB_File failed: $!\n";

    # Add the new values; remember which keys we've seen.
    while (<>) {
            chop;
            ($k, $v) = split;
            $new->insert($k, $v);
            $seen{$k} = 1;
    }

    # Add any old values that haven't been replaced.
    tie %old, 'CDB_File', $file or die "$0: can't tie to $file: $!\n";
    while (($k, $v) = each %old) {
            $new->insert($k, $v) unless $seen{$k};
    }

    $new->finish or die "$0: CDB_File finish failed: $!\n";

=head1 REPEATED KEYS

Most users can ignore this section.

A B<cdb> file can contain repeated keys.  If the C<insert> method is
called more than once with the same key during the creation of a B<cdb>
file, that key will be repeated.

Here's an example.

    $cdb = new CDB_File ("$file.cdb", "$file.$$") or die ...;
    $cdb->insert('cat', 'gato');
    $cdb->insert('cat', 'chat');
    $cdb->finish;

Normally, any attempt to access a key retrieves the first value
stored under that key.  This code snippet always prints B<gato>.

    $catref = tie %catalogue, CDB_File, "$file.cdb" or die ...;
    print "$catalogue{cat}";

However, all the usual ways of iterating over a hash---C<keys>,
C<values>, and C<each>---do the Right Thing, even in the presence of
repeated keys.  This code snippet prints B<cat cat gato chat>.

    print join(' ', keys %catalogue, values %catalogue);

Internally, B<CDB_File> stores extra information to keep track of where
it is while iterating over a file.  But this extra information is not
attached to multiple keys returned by C<keys>: if you use them to
retrieve values, they will always retrieve the first value stored under
that key.

This means that this code probably doesn't
do what you want; it prints B<cat:gato cat:gato>.

    foreach $key (keys %catalogue) {
            print "$key:$catalogue{$key} ";
    } 

The correct version uses C<each>, and prints B<cat:gato cat:chat>.

    while (($key, $val) = each %catalogue) {
            print "$key:$val ";
    }

In general, there is no way to retrieve all the values associated
with a key, other than to loop over the entire database (i.e. there
is no equivalent to B<DB_File>'s C<get_dup> method).  However, the
C<multi_get> method retrieves the values associated with the first
occurrence of a key, and all consecutive identical keys.  It returns a
reference to an array containing all the values.  If you ensure that
all occurrences of each key are adjacent in the database (perhaps by
C<sort>ing them during database creation), then C<multi_get> can be used
to retrieve all the values associated with a key.  This code prints
B<gato chat>.

    print "@{$catref->multi_get('cat')}";

=head1 RETURN VALUES

The routines C<tie>, C<new>, and C<finish> return B<false> if the
attempted operation failed; C<$!> contains the reason for failure.

=head1 DIAGNOSTICS

The following fatal errors may occur.  (See L<perlfunc/eval> if
you want to trap them.)

=over 4

=item Modification of a CDB_File attempted

You attempted to modify a hash tied to a B<CDB_File>.

=item CDB database too large

You attempted to create a B<cdb> file larger than 4 gigabytes.

=item Bad CDB_File format

You tried to C<use CDB_File> to access something that isn't a B<cdb>
file.

=item [ Write to | Read of | Seek in ] CDB_File failed: <error string>

The reported operation failed; the operating system's error string is
shown.  These errors can only occur if there is a serious problem, for
example, you have run out of disk space.

=item Use CDB_File::FIRSTKEY before CDB_File::NEXTKEY

If you are using the NEXTKEY method directly (I can't think of a reason
why you'd want to do this), you need to call FIRSTKEY first.

=back

=head1 BUGS

It ain't lightweight after you've plumbed Perl into it.

The Perl interface to B<cdb> imposes the restriction that data must fit
into memory.

=head1 SEE ALSO

cdb(3).

=head1 AUTHOR

Tim Goodwin, <tjg@star.le.ac.uk>, 1997-01-08 - 1999-09-08.

=cut

bootstrap CDB_File $VERSION;

sub CLEAR {
	croak "Modification of a CDB_File attempted"
}

sub DELETE {
	&CLEAR
}

sub STORE {
	&CLEAR
}

# Must be preloaded for the prototype.

sub create(\%$$) {
        my($RHdata, $fn, $fntemp) = @_;

        my $cdb = new CDB_File($fn, $fntemp) or return undef;
        my($k, $v);
        while (($k, $v) = each %$RHdata) {
                $cdb->insert($k, $v);
        }
        $cdb->finish;
        return 1;
}

1;

__END__

sub multi_get($$) {
	my($this, $key) = @_;

	return undef unless $this->EXISTS($key);

	my $ret = []; my $next;
	$this->FIRSTKEY;
	do {
		push @$ret, $this->FETCH($key);
		$next = $this->NEXTKEY($key)
	} while (defined $next and $next eq $key);

	$ret
}
