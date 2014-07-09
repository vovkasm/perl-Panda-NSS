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

BOOT:
    HV *stash = gv_stashpv("Panda::NSS", GV_ADD);

    newCONSTSUB(stash, "CERTIFICATE_USAGE_CHECK_ALL_USAGES", newSViv(certificateUsageCheckAllUsages));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_SSL_CLIENT", newSViv(certificateUsageSSLClient));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_SSL_SERVER", newSViv(certificateUsageSSLServer));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_SSL_SERVER_WITH_STEP_UP", newSViv(certificateUsageSSLServerWithStepUp));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_SSL_CA", newSViv(certificateUsageSSLCA));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_EMAIL_SIGNER", newSViv(certificateUsageEmailSigner));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_EMAIL_RECIPIENT", newSViv(certificateUsageEmailRecipient));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_OBJECT_SIGNER", newSViv(certificateUsageObjectSigner));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_USER_CERT_IMPORT", newSViv(certificateUsageUserCertImport));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_VERIFY_CA", newSViv(certificateUsageVerifyCA));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_PROTECTED_OBJECT_SIGNER", newSViv(certificateUsageProtectedObjectSigner));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_STATUS_RESPONDER", newSViv(certificateUsageStatusResponder));
    newCONSTSUB(stash, "CERTIFICATE_USAGE_ANY_CA", newSViv(certificateUsageAnyCA));

void
init(const char* configdir = NULL)
  CODE:
    if (!NSS_IsInitialized()) {
        SECStatus secStatus;
        if (configdir != NULL)
            secStatus = NSS_InitReadWrite(configdir);
        else
            secStatus = NSS_NoDB_Init(NULL);
        if (secStatus != SECSuccess) {
            PNSS_croak();
        }
    }

void
END()
  CODE:
    if (NSS_IsInitialized()) {
        int mod_type;
        SECMOD_DeleteModule("Builtins", &mod_type);
        NSS_Shutdown();
        PR_Cleanup();
    }


MODULE = Panda::NSS     PACKAGE = Panda::NSS::SecMod
PROTOTYPES: DISABLE

void
add_new_module(const char* module_name, const char* dll_path)
  PREINIT:
    SECStatus status;
  CODE:
    status = SECMOD_AddNewModule(module_name, dll_path, 0, 0);
    if (status != SECSuccess) {
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
simple_verify(Panda::NSS::Cert cert, int usage_iv = 0, double time_nv = 0)
  CODE:
    /* In params */
    CERTValInParam cvin[4];
    int cvinIdx = 0;

    SECCertificateUsage certUsage = usage_iv;

    if (certUsage < 0 || certUsage > certificateUsageHighest) {
        croak("Incorrect certificate usage value");
    }

    if (time_nv > 0) {
        time_nv *= 1000000;
        PRTime pr_time;
        LL_D2L(pr_time, time_nv);
        cvin[cvinIdx].type = cert_pi_date;
        cvin[cvinIdx].value.scalar.time = pr_time;
        ++cvinIdx;
    }

    cvin[cvinIdx].type = cert_pi_useAIACertFetch;
    cvin[cvinIdx].value.scalar.b = PR_TRUE;
    ++cvinIdx;

    cvin[cvinIdx].type = cert_pi_revocationFlags;
    cvin[cvinIdx].value.pointer.revocation = CERT_GetPKIXVerifyNistRevocationPolicy();
    ++cvinIdx;

    cvin[cvinIdx].type = cert_pi_end;

    /* Out params */
    CERTValOutParam cvout[4];
    int cvoutIdx = 0;

    cvout[cvoutIdx].type = cert_po_trustAnchor;
    cvout[cvoutIdx].value.pointer.cert = NULL;
    ++cvoutIdx;

    cvout[cvoutIdx].type = cert_po_certList;
    cvout[cvoutIdx].value.pointer.chain = NULL;
    ++cvoutIdx;

    CERTVerifyLog log;
    log.arena = PORT_NewArena(512);
    log.head = log.tail = NULL;
    log.count = 0;

    cvout[cvoutIdx].type = cert_po_errorLog;
    cvout[cvoutIdx].value.pointer.log = &log;
    ++cvoutIdx;

    cvout[cvoutIdx].type = cert_po_end;

    SECStatus secStatus = CERT_PKIXVerifyCert(cert, certUsage, cvin, cvout, NULL);
    if (secStatus == SECSuccess) {
        RETVAL = 1;
    }
    else {
        RETVAL = 0;
    }

    CERTCertificate* issuerCert = cvout[0].value.pointer.cert;
    if (issuerCert) {
        CERT_DestroyCertificate(issuerCert);
    }

    CERTCertList* builtChain = cvout[1].value.pointer.chain;
    if (builtChain) {
        CERT_DestroyCertList(builtChain);
    }

    for (CERTVerifyLogNode* node = log.head; node; node = node->next) {
        if (node->cert) CERT_DestroyCertificate(node->cert);
    }

    PORT_FreeArena(log.arena, PR_FALSE);

  OUTPUT:
    RETVAL

void
DESTROY(Panda::NSS::Cert cert)
  CODE:
    CERT_DestroyCertificate(cert);
    cert = NULL;
