# kind of duplicate of Makefile.PL
#	but convenient for Continuous Integration

on 'test' => sub {
    requires 'B::COW'                      => 0;
    requires 'Devel::Peek'                 => 0;
    requires 'Devel::PPPort'               => '3.58';
    requires 'File::Temp'                  => 0;
    requires 'Test::More'                  => 0;
    requires 'ExtUtils::MakeMaker::PPPort' => '0.02';
};
