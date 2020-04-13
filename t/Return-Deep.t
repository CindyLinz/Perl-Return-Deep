# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Return-Deep.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 30;
BEGIN { use_ok('Return::Deep') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @Output;
my $Depth;

sub a {
    push @Output, "[a begin]";
    my @ret = eval {
        push @Output, "[a-eval begin]";
        my @ret = b();
        push @Output, "[a-eval end with", @ret, "]";
    };
    push @Output, "[a end with", @ret, "]";
}

sub b {
    push @Output, "[b begin]";
    my @ret = c();
    push @Output, "[b end with", @ret, "]";
}

sub c {
    push @Output, "[c begin]";
    my @ret = deep_ret($Depth, 3, 2, 'a');
    push @Output, "[c end with", @ret, "]";
}

sub test {
    $Depth = $_[0];

    @Output = "[test begin]";
    my @ret = a();
    push @Output, "[test end with", @ret, "]";

    is("@Output", $_[1], "test($_[0])");
}

no warnings 'uninitialized';

my $Symbol;

sub xx {
    push @Output, "[xx begin]";
    my @ret = ret_bound {
        push @Output, "[xx ret_bound begin]";
        my @ret = yy();
        push @Output, "[xx ret_bound end with @ret]";
    } 'xx';
    push @Output, "[xx end with @ret]";
}

sub yy {
    push @Output, "[yy begin]";
    my @ret = ret_bound {
        push @Output, "[yy ret_bound begin]";
        my @ret = zz();
        push @Output, "[yy ret_bound end with @ret]";
    } $] >= 5.010000 ? qr/^yy/ : 'yy';
    push @Output, "[yy end with @ret]";
}

sub zz {
    push @Output, "[zz begin]";
    my @ret = ret_bound {
        push @Output, "[zz ret_bound begin]";
        my @ret = sym_ret($Symbol, 2, 3, 'a');
        push @Output, "[zz ret_bound end with @ret]";
    } 'zz';
    push @Output, "[zz end with @ret]";
}

sub test_sym {
    $Symbol = $_[0];

    @Output = ("[test_sym begin]");
    my @ret = ret_bound {
        push @Output, "[test_sym ret_bound begin]";
        my @ret = xx();
        push @Output, "[test_sym ret_bound end with @ret]";
    };
    push @Output, "[test_sym end with @ret]";

    is("@Output", $_[1], "test_sym($_[0])");
}

test(0, '[test begin] [a begin] [a-eval begin] [b begin] [c begin] [c end with 3 2 a ] [b end with 10 ] [a-eval end with 13 ] [a end with 16 ] [test end with 19 ]');
test(1, '[test begin] [a begin] [a-eval begin] [b begin] [c begin] [b end with 3 2 a ] [a-eval end with 10 ] [a end with 13 ] [test end with 16 ]');
test(2, '[test begin] [a begin] [a-eval begin] [b begin] [c begin] [a-eval end with 3 2 a ] [a end with 10 ] [test end with 13 ]');
test(3, '[test begin] [a begin] [a-eval begin] [b begin] [c begin] [a end with 3 2 a ] [test end with 10 ]');
test(4, '[test begin] [a begin] [a-eval begin] [b begin] [c begin] [test end with 3 2 a ]');

test_sym('yy', '[test_sym begin] [test_sym ret_bound begin] [xx begin] [xx ret_bound begin] [yy begin] [yy ret_bound begin] [zz begin] [zz ret_bound begin] [yy end with 2 3 a] [xx ret_bound end with 9] [xx end with 10] [test_sym ret_bound end with 11] [test_sym end with 12]');
test_sym('xx', '[test_sym begin] [test_sym ret_bound begin] [xx begin] [xx ret_bound begin] [yy begin] [yy ret_bound begin] [zz begin] [zz ret_bound begin] [xx end with 2 3 a] [test_sym ret_bound end with 9] [test_sym end with 10]');
test_sym('zz', '[test_sym begin] [test_sym ret_bound begin] [xx begin] [xx ret_bound begin] [yy begin] [yy ret_bound begin] [zz begin] [zz ret_bound begin] [zz end with 2 3 a] [yy ret_bound end with 9] [yy end with 10] [xx ret_bound end with 11] [xx end with 12] [test_sym ret_bound end with 13] [test_sym end with 14]');
test_sym('any', '[test_sym begin] [test_sym ret_bound begin] [xx begin] [xx ret_bound begin] [yy begin] [yy ret_bound begin] [zz begin] [zz ret_bound begin] [test_sym end with 2 3 a]');
test_sym('', '[test_sym begin] [test_sym ret_bound begin] [xx begin] [xx ret_bound begin] [yy begin] [yy ret_bound begin] [zz begin] [zz ret_bound begin] [test_sym end with 2 3 a]');
test_sym(undef, '[test_sym begin] [test_sym ret_bound begin] [xx begin] [xx ret_bound begin] [yy begin] [yy ret_bound begin] [zz begin] [zz ret_bound begin] [test_sym end with 2 3 a]');
if( $] >= 5.010000 ) {
    test_sym('yyy', '[test_sym begin] [test_sym ret_bound begin] [xx begin] [xx ret_bound begin] [yy begin] [yy ret_bound begin] [zz begin] [zz ret_bound begin] [yy end with 2 3 a] [xx ret_bound end with 9] [xx end with 10] [test_sym ret_bound end with 11] [test_sym end with 12]');
    test_sym('ayy', '[test_sym begin] [test_sym ret_bound begin] [xx begin] [xx ret_bound begin] [yy begin] [yy ret_bound begin] [zz begin] [zz ret_bound begin] [test_sym end with 2 3 a]');
}
else {
    test_sym('yyy', '[test_sym begin] [test_sym ret_bound begin] [xx begin] [xx ret_bound begin] [yy begin] [yy ret_bound begin] [zz begin] [zz ret_bound begin] [test_sym end with 2 3 a]');
    test_sym('ayy', '[test_sym begin] [test_sym ret_bound begin] [xx begin] [xx ret_bound begin] [yy begin] [yy ret_bound begin] [zz begin] [zz ret_bound begin] [test_sym end with 2 3 a]');
}

sub translate_wantarray {
    if( defined($_[0]) ) {
        return 1 if( $_[0] );
        return 0;
    }
    return -1;
}
sub wantarray_a {
    my $res = ret_bound { # scalar
        wantarray_b(); # void
        return;
    } 'a';
}
sub wantarray_b {
    my @res = ret_bound { # array
        my $res = wantarray_c(); # scalar
    } 'b';
}
sub wantarray_c {
    ret_bound { # void
        my @res = wantarray_d(); # array
    } 'c';
    return;
}
sub wantarray_d {
    is(translate_wantarray(deep_wantarray(1)), 1, 'deep_wantarray(1)');
    is(translate_wantarray(deep_wantarray(2)), -1, 'deep_wantarray(2)');
    is(translate_wantarray(deep_wantarray(3)), -1, 'deep_wantarray(3)');
    is(translate_wantarray(deep_wantarray(4)), 0, 'deep_wantarray(4)');
    is(translate_wantarray(deep_wantarray(5)), 1, 'deep_wantarray(5)');
    is(translate_wantarray(deep_wantarray(6)), 1, 'deep_wantarray(6)');
    is(translate_wantarray(deep_wantarray(7)), -1, 'deep_wantarray(7)');
    is(translate_wantarray(deep_wantarray(8)), 0, 'deep_wantarray(8)');
    is(translate_wantarray(deep_wantarray(9)), 0, 'deep_wantarray(9)');
    is(translate_wantarray(deep_wantarray(10)), 0, 'deep_wantarray(10)');
    is(translate_wantarray(deep_wantarray(11)), -1, 'deep_wantarray(11)');
    is(translate_wantarray(deep_wantarray(12)), -1, 'deep_wantarray(12)');

    is(translate_wantarray(sym_wantarray('a')), 0, "sym_wantarray('a')");
    is(translate_wantarray(sym_wantarray('b')), 1, "sym_wantarray('b')");
    is(translate_wantarray(sym_wantarray('c')), -1, "sym_wantarray('c')");
    is(translate_wantarray(sym_wantarray('d')), -1, "sym_wantarray('d')");
}

scalar wantarray_a();
