use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker;

my $MIN_DEVEL_PPPORT = q[3.58];

WriteMakefile(
    'NAME'          => 'CDB_File',
    'AUTHOR'        => 'Todd E Rinaldo <toddr@cpan.org>',
    'VERSION_FROM'  => 'CDB_File.pm',
    'ABSTRACT_FROM' => 'CDB_File.pm',
    'PL_FILES'      => {},
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'perl', ) : () ),
    ( ( $Config{'d_mmap'} && $Config{'d_mmap'} eq 'define' ) ? ( 'DEFINE' => '-DHASMMAP' ) : () ),
    PREREQ_PM => {
        'Test::More'  => 0,    # For testing
        'B::COW'      => 0,    # For testing
        'File::Temp'  => 0,    # For testing
        'Devel::Peek' => 0,    # For testing
        'Devel::PPPort' => $MIN_DEVEL_PPPORT,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'CDB_File-*' },
    META_MERGE => {
        recommends     => {},
        build_requires => {
            'Test::More' => 0,    # For testing
            'B::COW'      => 0,    # For testing
            'File::Temp'  => 0,    # For testing
            'Devel::Peek' => 0,    # For testing
            'Devel::PPPort' => $MIN_DEVEL_PPPORT,
        },
        resources => {
            license  => 'http://dev.perl.org/licenses/',
            bugtracker => 'https://github.com/toddr/CDB_File/issues',
            repository => 'https://github.com/toddr/CDB_File',
        },
    },
    postamble => {
        MIN_DEVEL_PPPORT => $MIN_DEVEL_PPPORT,
    },
);

# would be nice to integrate the logic itself inside ExtUtil::MakeMaker
# with something like
# Neeed_Devel_PPPORT => 3.58

sub MY::top_targets
{
  package MY;
  my $content = shift->SUPER::top_targets(@_);
  $content =~ s{^(pure_all\s*::\s*)}{${1}ppport }m;
  return $content;
}

sub MY::clean
{
  package MY;
  my $content = shift->SUPER::clean(@_);
  $content =~ s{^(clean\s*::\s*)}{${1}ppport_clean }m;
  warn $content;
  return $content;
}

sub MY::postamble
{
  package MY;
  my ( $self, %extra ) = @_;

  my $post = $self->SUPER::postamble(%extra);
  my $min_version = $extra{MIN_DEVEL_PPPORT} || 0;

  $post .= <<'POSTAMBLE';

# ppport targets

.PHONY: ppport ppport_version ppport_clean

ppport: ppport_version ppport.h
~TAB~$(NOECHO) $(NOOP)

ppport_version:
~TAB~@$(PERL) -I$(INST_LIB) -MDevel::PPPort -e 'die qq[Needs Devel-PPPort version >= ~MIN_DEVEL_PPPORT~ # got $$Devel::PPPort::VERSION] unless $$Devel::PPPort::VERSION >= ~MIN_DEVEL_PPPORT~'

ppport_clean:
~TAB~- $(RM_F) ppport.h

ppport.h :
~TAB~@$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MDevel::PPPort -e'Devel::PPPort::WriteFile'

POSTAMBLE

    $post =~ s{~MIN_DEVEL_PPPORT~}{$min_version}g;
    $post =~ s{~TAB~}{\t}g;

  return $post;
}
