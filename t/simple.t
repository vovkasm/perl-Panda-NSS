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

ok !!$cert->simple_verify(Panda::NSS::CERTIFICATE_USAGE_OBJECT_SIGNER, $vfytime), 'Correctly fetch all intermediate certs and check chain';
ok !$cert->simple_verify(Panda::NSS::CERTIFICATE_USAGE_OBJECT_SIGNER, 10), 'Not valid in the distant past';

is $cert->version, 3, "Version 3";
is $cert->serial_number_hex, "02485F1606A9E9776E77E39E5444F627", "serial number correct";
my $hex = uc( join("", unpack("H*", $cert->serial_number)) );
is $hex, $cert->serial_number_hex, "binary serial number correct";
is $cert->subject, 'CN=Apple Inc.,OU=Digital ID Class 3 - Java Object Signing,OU=GC Sandbox - IS Delivery Engineering,O=Apple Inc.,L=Cupertino,ST=CA,C=US', 'Subject correct';
is $cert->issuer, 'CN=VeriSign Class 3 Code Signing 2010 CA,OU=Terms of use at https://www.verisign.com/rpa (c)10,OU=VeriSign Trust Network,O="VeriSign, Inc.",C=US', 'Issuer correct';
is $cert->common_name, 'Apple Inc.', 'Common name correct';
is $cert->country_name, 'US', 'Country name correct';
is $cert->locality_name, 'Cupertino', 'Locality name correct';
is $cert->state_name, 'CA', 'State name correct';
is $cert->org_name, 'Apple Inc.', 'Org name correct';
is $cert->org_unit_name, 'GC Sandbox - IS Delivery Engineering', 'Org Unit name correct';
is $cert->domain_component_name, undef, 'Domain Component name correct';

done_testing;

sub slurp {
  local $/;
  open my $file, $_[0] or die "Couldn't open file: $!";
  return <$file>;
}
