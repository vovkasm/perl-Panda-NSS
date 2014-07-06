use ExtUtils::MakeMaker;

my $nss_libs = `pkg-config --libs nss`;
my $nss_cflags = `pkg-config --cflags nss`;

WriteMakefile(
    NAME => 'Panda::NSS',
    VERSION_FROM => 'NSS.pm',
    AUTHOR => 'Vladimir Timofeev <vovkasm@gmail.com>',
    LICENSE => 'perl',
    BUILD_REQUIRES => {
        'Test::More' => 0.88,
    },
    CCFLAGS => $nss_cflags,
    LIBS => [$nss_libs],
);
