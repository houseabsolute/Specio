#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* All of this was copied from Moose */

/*
SvRXOK appeared before SVt_REGEXP did, so this implementation assumes magic
based qr//. Note re::is_regexp isn't in 5.8, hence the need for this XS.
*/
#ifndef SvRXOK
#define SvRXOK(sv) is_regexp(aTHX_ sv)

STATIC int
is_regexp (pTHX_ SV* sv) {
  SV* tmpsv;

  if (SvMAGICAL(sv)) {
    mg_get(sv);
  }

  if (SvROK(sv) &&
      (tmpsv = (SV*) SvRV(sv)) &&
      SvTYPE(tmpsv) == SVt_PVMG &&
      (mg_find(tmpsv, PERL_MAGIC_qr))) {
    return TRUE;
  }

  return FALSE;
}
#endif

MODULE = Type::Library::Builtins  PACKAGE = Type::Library::Builtins

PROTOTYPES: DISABLE

bool
_RegexpRef (SV *sv)
  CODE:
    RETVAL = SvRXOK(sv);
  OUTPUT:
    RETVAL
