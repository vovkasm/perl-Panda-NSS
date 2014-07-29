package inc::DistMakeMaker;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
    my ($self) = @_;
    my $base_tmpl = super();
    my $preamble = <<'END_PREAMBLE';
use PkgConfig;
my $nss_config = PkgConfig->find('nss');
if ($nss_config->errmsg) {
    die "To build this module you need NSS installed!";
}
END_PREAMBLE
    my $tmpl = $preamble.$base_tmpl;
    return $tmpl;
};

__PACKAGE__->meta->make_immutable;
