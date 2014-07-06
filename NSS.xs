#include <nspr.h>
#include <nss.h>

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"


MODULE = Panda::NSS     PACKAGE = Panda::NSS
PROTOTYPES: DISABLE

BOOT: {

}
