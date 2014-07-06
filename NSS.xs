#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

#include <nspr.h>
#include <nss.h>


MODULE = Panda::NSS     PACKAGE = Panda::NSS
PROTOTYPES: DISABLE

BOOT:
    ;

