use ExtUtils::MakeMaker;

my $nss_libs = `pkg-config --libs nss`;
my $nss_cflags = `pkg-config --cflags nss`;
#my $nss_libs = '-L/Users/vovkasm/work/dist/Darwin13.2.0_64_DBG.OBJ/lib -L/usr/local/Cellar/nspr/4.10.6/lib -lnss3 -lnssutil3 -lsmime3 -lssl3 -lplds4 -lplc4 -lnspr4';
#my $nss_cflags = '-I/Users/vovkasm/work/dist/public/nss -I/usr/local/Cellar/nspr/4.10.6/include/nspr';

WriteMakefile(
    NAME => 'Panda::NSS',
    VERSION_FROM => 'lib/Panda/NSS.pm',
    AUTHOR => 'Vladimir Timofeev <vovkasm@gmail.com>',
    LICENSE => 'perl',
    BUILD_REQUIRES => {
        'Test::More' => 0.88,
        'Test::SharedFork' => 0.28,
    },
    CCFLAGS => $nss_cflags,
    LIBS => [$nss_libs],
);
