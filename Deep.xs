#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

Perl_ppaddr_t return_ppaddr;

OP * my_pp_deep_ret(pTHX){
    dSP; POPs;

    IV depth = SvIV(PL_stack_base[TOPMARK+1]);

    for(SV ** p = PL_stack_base+TOPMARK; p<SP; ++p)
        *p = *(p+1);
    POPs;

    if( depth <= 0 )
        RETURN;

    OP * next_op;
    while( depth-- )
        next_op = return_ppaddr(aTHX);
    RETURNOP(next_op);
}

OP * deep_ret_check(pTHX_ OP * o, GV * namegv, SV * ckobj){
    o->op_ppaddr = my_pp_deep_ret;
    return o;
}

MODULE = Return::Deep		PACKAGE = Return::Deep		

INCLUDE: const-xs.inc

BOOT:
    return_ppaddr = PL_ppaddr[OP_RETURN];

    cv_set_call_checker(get_cv("Return::Deep::deep_ret", TRUE), deep_ret_check, &PL_sv_undef);
