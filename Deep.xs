#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) (PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef G_WANT
#define G_WANT (G_VOID|G_SCALAR|G_ARRAY)
#endif

struct block_symbol_t {
    CV * cv;
    SV * symbol_SV;
};

static Perl_ppaddr_t return_ppaddr;
static struct block_symbol_t * block_symbols;
static int block_symbols_capacity, block_symbols_n;

static SV * regex_match_sv;

static OP * my_pp_deep_ret(pTHX){
    dSP; POPs;

    IV depth = SvIV(PL_stack_base[TOPMARK+1]);

    for(SV ** p = PL_stack_base+TOPMARK+1; p<SP; ++p)
        *p = *(p+1);
    POPs;

    if( depth <= 0 )
        RETURN;

    OP * next_op;
    while( depth-- )
        next_op = return_ppaddr(aTHX);
    RETURNOP(next_op);
}

static OP * my_pp_sym_ret(pTHX){
    dSP; POPs;

    SV * symbol_SV = PL_stack_base[TOPMARK+1];

    for(SV ** p = PL_stack_base+TOPMARK+1; p<SP; ++p)
        *p = *(p+1);
    POPs;

    while(TRUE){
        for(PERL_CONTEXT * cx = &cxstack[cxstack_ix]; cx>=cxstack; --cx){
            switch( CxTYPE(cx) ){
                default:
                    continue;
                case CXt_SUB:
#if PERL_VERSION_GE(5,18,0)
                    if( cx->cx_type & CXp_SUB_RE_FAKE )
                        continue;
#endif
                    for(struct block_symbol_t *p = block_symbols+block_symbols_n-1; p>=block_symbols; --p)
                        if( p->cv == cx->blk_sub.cv ){
                            if( !SvOK(p->symbol_SV) )
                                RETURNOP(return_ppaddr(aTHX));
#if PERL_VERSION_GE(5,10,0)
                            if( SvRXOK(p->symbol_SV) ){
                                PUSHMARK(SP);
                                EXTEND(SP, 2);
                                PUSHs(p->symbol_SV);
                                PUSHs(symbol_SV);
                                PUTBACK;
                                call_sv(regex_match_sv, G_SCALAR);
                                SPAGAIN;
                                IV match_res = POPi;
                                PUTBACK;

                                if( match_res )
                                    RETURNOP(return_ppaddr(aTHX));
                            }
                            else
#endif
                                if( sv_cmp(p->symbol_SV, symbol_SV)==0 )
                                    RETURNOP(return_ppaddr(aTHX));
                        }
                case CXt_EVAL:
                case CXt_FORMAT:
                    goto DO_RETURN;
            }
        }
        DO_RETURN:
        return_ppaddr(aTHX);
    }
}

static OP * deep_ret_check(pTHX_ OP * o, GV * namegv, SV * ckobj){
    o->op_ppaddr = my_pp_deep_ret;
    return o;
}

static OP * sym_ret_check(pTHX_ OP * o, GV * namegv, SV * ckobj){
    o->op_ppaddr = my_pp_sym_ret;
    return o;
}

static int guard_free(pTHX_ SV * guard_SV, MAGIC * mg){
    for(struct block_symbol_t * p=block_symbols+block_symbols_n-1; p>=block_symbols; --p)
        if( (IV)p->cv == (IV)mg->mg_ptr ){
            --block_symbols_n;
            *p = block_symbols[block_symbols_n];
            break;
        }
    return 0;
}

static MGVTBL guard_vtbl = {
    0, 0, 0, 0,
    guard_free
};

#if !PERL_VERSION_GE(5,14,0)
static CV* my_deep_ret_cv;
static CV* my_sym_ret_cv;
static OP* (*orig_entersub_check)(pTHX_ OP*);
static OP* my_entersub_check(pTHX_ OP* o){
    CV *cv = NULL;
    OP *cvop = OpSIBLING(((OpSIBLING(cUNOPo->op_first)) ? cUNOPo : ((UNOP*)cUNOPo->op_first))->op_first);
    while( OpSIBLING(cvop) )
        cvop = OpSIBLING(cvop);
    if( cvop->op_type == OP_RV2CV && !(o->op_private & OPpENTERSUB_AMPER) ){
        SVOP *tmpop = (SVOP*)((UNOP*)cvop)->op_first;
        switch (tmpop->op_type) {
            case OP_GV: {
                GV *gv = cGVOPx_gv(tmpop);
                cv = GvCVu(gv);
                if (!cv)
                    tmpop->op_private |= OPpEARLY_CV;
            } break;
            case OP_CONST: {
               SV *sv = cSVOPx_sv(tmpop);
               if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV)
                   cv = (CV*)SvRV(sv);
           } break;
        }
        if( cv==my_deep_ret_cv )
            o->op_ppaddr = my_pp_deep_ret;
        if( cv==my_sym_ret_cv )
            o->op_ppaddr = my_pp_sym_ret;
    }
    return orig_entersub_check(aTHX_ o);
}
#endif

MODULE = Return::Deep		PACKAGE = Return::Deep		

INCLUDE: const-xs.inc

void add_bound(SV * act_SV, SV * symbol_SV)
    PPCODE:
        if( !(SvOK(act_SV) && SvROK(act_SV) && SvTYPE(SvRV(act_SV))==SVt_PVCV) )
            croak("there should be a code block");

        CV * act_CV = (CV*) SvRV(act_SV);
        SV * guard_SV = newSV(0);

        sv_magicext(guard_SV, NULL, PERL_MAGIC_ext, &guard_vtbl, (char*) act_CV, 0);

        if( block_symbols_n >= block_symbols_capacity ){
            block_symbols_capacity *= 2;
            Renew(block_symbols, block_symbols_capacity, struct block_symbol_t);
        }
        block_symbols[block_symbols_n].cv = act_CV;
        block_symbols[block_symbols_n].symbol_SV = symbol_SV;
        ++block_symbols_n;

        PUSHs(sv_2mortal(newRV_noinc(guard_SV)));

void deep_wantarray(IV depth)
    PPCODE:
        if( depth<1 )
            croak("deep_wantarray with non-positive depth");

        PERL_CONTEXT * cx = &cxstack[cxstack_ix];
        for(; cx>=cxstack; --cx)
            switch( CxTYPE(cx) ){
                default:
                    continue;
                case CXt_SUB:
#if PERL_VERSION_GE(5,18,0)
                    if( cx->cx_type & CXp_SUB_RE_FAKE )
                        continue;
#endif
                case CXt_EVAL:
                case CXt_FORMAT:
                    if( --depth <= 0 )
                        goto FOUND;
            }
        FOUND:

        if( cx<cxstack )
            PUSHs(&PL_sv_undef);
        else
            switch(cx->blk_gimme & G_WANT){
                case G_VOID:
                    PUSHs(&PL_sv_undef);
                    break;
                case G_SCALAR:
                    PUSHs(&PL_sv_no);
                    break;
                case G_ARRAY:
                    PUSHs(&PL_sv_yes);
                    break;
                default:
                    croak("Unknown wantarray");
            }

void sym_wantarray(SV * symbol_SV)
    PPCODE:
        PERL_CONTEXT * cx = &cxstack[cxstack_ix];
        for(; cx>=cxstack; --cx){
            switch( CxTYPE(cx) ){
                default:
                    continue;
                case CXt_SUB:
#if PERL_VERSION_GE(5,18,0)
                    if( cx->cx_type & CXp_SUB_RE_FAKE )
                        continue;
#endif
                    for(struct block_symbol_t *p = block_symbols+block_symbols_n-1; p>=block_symbols; --p)
                        if( p->cv == cx->blk_sub.cv ){
                            if( !SvOK(p->symbol_SV) )
                                break;
#if PERL_VERSION_GE(5,10,0)
                            if( SvRXOK(p->symbol_SV) ){
                                PUSHMARK(SP);
                                EXTEND(SP, 2);
                                PUSHs(p->symbol_SV);
                                PUSHs(symbol_SV);
                                PUTBACK;
                                call_sv(regex_match_sv, G_SCALAR);
                                SPAGAIN;
                                IV match_res = POPi;
                                PUTBACK;

                                if( match_res )
                                    goto FOUND;
                            }
                            else
#endif
                                if( sv_cmp(p->symbol_SV, symbol_SV)==0 )
                                    goto FOUND;
                        }
                case CXt_EVAL:
                case CXt_FORMAT:
                    break;
            }
        }
        FOUND:
        if( cx<cxstack )
            PUSHs(&PL_sv_undef);
        else
            switch(cx->blk_gimme & G_WANT){
                case G_VOID:
                    PUSHs(&PL_sv_undef);
                    break;
                case G_SCALAR:
                    PUSHs(&PL_sv_no);
                    break;
                case G_ARRAY:
                    PUSHs(&PL_sv_yes);
                    break;
                default:
                    croak("Unknown wantarray");
            }

BOOT:
    block_symbols_capacity = 8;
    block_symbols_n = 0;
    Newx(block_symbols, block_symbols_capacity, struct block_symbol_t);

    regex_match_sv = newRV_inc((SV*)get_cv("Return::Deep::regex_match", FALSE));

    return_ppaddr = PL_ppaddr[OP_RETURN];
#if PERL_VERSION_GE(5,14,0)
    cv_set_call_checker(get_cv("Return::Deep::deep_ret", TRUE), deep_ret_check, &PL_sv_undef);
    cv_set_call_checker(get_cv("Return::Deep::sym_ret", TRUE), sym_ret_check, &PL_sv_undef);
#else
    my_deep_ret_cv = get_cv("Return::Deep::deep_ret", TRUE);
    my_sym_ret_cv = get_cv("Return::Deep::sym_ret", TRUE);
    orig_entersub_check = PL_check[OP_ENTERSUB];
    PL_check[OP_ENTERSUB] = my_entersub_check;
#endif
