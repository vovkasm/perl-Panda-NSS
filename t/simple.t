use strict;
use warnings;
use Test::More;
use Panda::NSS;

my $vfytime = 1404206968;

Panda::NSS::init();

my $cert_data = slurp('t/has_aia.cer');
my $cert = Panda::NSS::Cert->new($cert_data);

is($cert->verify($vfytime), 1, 'Correctly fetch all intermediate certs and check chain');
#TODO: is($cert->verify($vfytime, Panda::NSS::certUsageObjectSigner), 1, 'Correctly fetch all intermediate certs and check chain');

done_testing;

sub slurp {
  local $/;
  open my $file, $_[0] or die "Couldn't open file: $!";
  return <$file>;
}
