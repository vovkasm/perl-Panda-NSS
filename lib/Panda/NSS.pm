package Panda::NSS;
use strict;
use warnings;
use Config ();

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub add_builtins {
    my $suffix = $Config::Config{so};
    my $prefix = '';
    $prefix = 'lib' unless $suffix eq 'dll';
    Panda::NSS::SecMod::add_new_module("Builtins", "${prefix}nssckbi.$suffix");
}

1;
