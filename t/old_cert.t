use strict;
use warnings;
use File::Temp 'tempdir';
use Test::More;
use Panda::NSS;

my $vfytime = 1404206968;

my $tmpdir = tempdir(CLEANUP => 1);

Panda::NSS::init($tmpdir);
Panda::NSS::add_builtins();

Panda::NSS::init($tmpdir );
my $ok = 0;
$ok = eval{ Panda::NSS::add_builtins(); 1; };

diag $@ unless is $ok, 1;

done_testing;
