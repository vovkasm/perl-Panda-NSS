#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

#include <nspr.h>
#include <nss.h>
#include <secmod.h>
#include <cert.h>
#include <prerror.h>

#define DLL_PREFIX "lib"
#define DLL_SUFFIX "dylib"

typedef CERTCertificate* Panda__NSS__Cert;

static
void
PNSS_croak() {
    PRErrorCode code = PR_GetError();
    const char* msg = PR_ErrorToString(code, PR_LANGUAGE_I_DEFAULT);
    SV* sv = newSVpv(msg, 0);
    croak_sv(sv_2mortal(sv));
}

MODULE = Panda::NSS     PACKAGE = Panda::NSS
PROTOTYPES: DISABLE

void
init()
CODE:
    SECStatus secStatus;
    secStatus = NSS_NoDB_Init(NULL);
    SECMOD_AddNewModule("Builtins", DLL_PREFIX"nssckbi."DLL_SUFFIX, 0, 0);
    if (secStatus != SECSuccess) {
        PNSS_croak();
    }


MODULE = Panda::NSS     PACKAGE = Panda::NSS::Cert
PROTOTYPES: DISABLE

Panda::NSS::Cert
new(klass, SV* cert_sv)
  PREINIT:
    CERTCertificate *cert;
    CERTCertDBHandle *defaultDB;

  CODE:
    defaultDB = CERT_GetDefaultCertDB();

    STRLEN len;
    char* data = SvPV(cert_sv, len);

    SECItem item = {siBuffer, NULL, len};
    item.data = (unsigned char*)PORT_Alloc(len);
    PORT_Memcpy(item.data, data, len);

    /* CERT_NewTempCertificate( defaultDB, item, nickname, isPerm, copyDER) */
    cert = CERT_NewTempCertificate(defaultDB, &item, NULL, PR_FALSE, PR_TRUE);
    if (!cert) {
        PORT_Free(item.data);
        PNSS_croak();
    }
    PORT_Free(item.data);

    RETVAL = cert;

  OUTPUT:
    RETVAL

int
verify(Panda::NSS::Cert cert, int time = 0)
  CODE:
    /* In params */
    CERTValInParam cvin[3];
    cvin[0].type = cert_pi_useAIACertFetch;
    cvin[0].value.scalar.b = PR_TRUE;

    cvin[1].type = cert_pi_revocationFlags;
    cvin[1].value.pointer.revocation = CERT_GetPKIXVerifyNistRevocationPolicy();

    cvin[2].type = cert_pi_end;

    /* Out params */
    CERTValOutParam cvout[4];

    cvout[0].type = cert_po_trustAnchor;
    cvout[0].value.pointer.cert = NULL;

    cvout[1].type = cert_po_certList;
    cvout[1].value.pointer.chain = NULL;

    CERTVerifyLog log;
    log.arena = PORT_NewArena(512);
    log.head = log.tail = NULL;
    log.count = 0;

    cvout[2].type = cert_po_errorLog;
    cvout[2].value.pointer.log = &log;

    cvout[3].type = cert_po_end;

    SECCertificateUsage  certUsage = certificateUsageObjectSigner;

    SECStatus secStatus = CERT_PKIXVerifyCert(cert, certUsage, cvin, cvout, NULL);
    if (secStatus == SECSuccess) {
        RETVAL = 1;
    }
    else {
        PNSS_croak();
        RETVAL = 0;
    }

  OUTPUT:
    RETVAL

