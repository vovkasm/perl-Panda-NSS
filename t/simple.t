use strict;
use warnings;
use File::Temp 'tempdir';
use Test::More;
use Panda::NSS;

my $vfytime = 1404206968;

my $tmpdir = tempdir(CLEANUP => 1);
note "NSS DB dir = $tmpdir";

Panda::NSS::init($tmpdir);
Panda::NSS::add_builtins();

my $cert_data = slurp('t/has_aia.cer');
my $cert = Panda::NSS::Cert->new($cert_data);

ok(!!$cert->simple_verify(Panda::NSS::CERTIFICATE_USAGE_OBJECT_SIGNER, $vfytime), 'Correctly fetch all intermediate certs and check chain');
ok(!$cert->simple_verify(Panda::NSS::CERTIFICATE_USAGE_OBJECT_SIGNER, 10), 'Not valid in the distant past');
#TODO: is($cert->verify($vfytime, Panda::NSS::certUsageObjectSigner), 1, 'Correctly fetch all intermediate certs and check chain');

done_testing;

sub slurp {
  local $/;
  open my $file, $_[0] or die "Couldn't open file: $!";
  return <$file>;
}
