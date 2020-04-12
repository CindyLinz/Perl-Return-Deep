# NAME

Return::Deep - deeply returns through multiple layers at once

# SYNOPSIS

    use Return::Deep;

    sub a {
      b();
      # never goes here
    }

    sub b {
      deep_ret(2, 'Hi', 42);
    }

    my @ret = a();
    # got ('Hi', 42) here

    my @outer_ret = ret_bound {
      my @regex_ret = ret_bound {
        my @inner_ret = ret_bound {
          if( .2 < rand ) {
              sym_ret('inner', 43); # @inner_ret got 43
          }
          elsif( .5 < rand ) {
              sym_ret('Error::SomeError', 45); # @regex_ret got 45
          }
          else {
              sym_ret('any', 43); # @outer_ret got 44
          }
        } 'inner'; # catch 'inner'
      } qr/^Error::/; # catch all symbols which begin with 'Error::' by regex
    }; # catch all symbols without a catch symbol

# DESCRIPTION

Deeply returns through multiple layers at once.

## EXPORT

- deep\_ret($depth, @return\_value)

    If `$depth` = 1, it performs like a normal return.

    If `$depth` <= 0, it performs like a normal list.

    If `$depth` > 1, it returns through many layers, including subs and eval blocks.

- sym\_ret($symbol, @return\_value)

    Return through many layers, until the `$symbol` is catched by a matched `ret_bound`.

- ret\_bound {CODE\_BLOCK} $catch\_symbol
- ret\_bound {CODE\_BLOCK}

    Catch matched `sym_ret`s. Without the `$catch_symbol`, it will catch all the `sym_ret`.

    `$catch_symbol` could be a string or a regular expression (`qr/something/`).
    If `$catch_symbol` is a string, it will catch `sym_ret` with an exactly match.
    If `$catch_symbol` is a regular expression, it will catch `sym_ret` with a regular expression test.

    (`$catch_symbol` with regular expresion is not supported before Perl 5.10)

Tested on Perl version 5.30.2, 5.28.2, 5.26.3, 5.24.4, 5.22.4, 5.20.3, 5.18.4, 5.16.3, 5.14.4, 5.12.5, 5.10.1, 5.8.9.

# SEE ALSO

This mod's github [https://github.com/CindyLinz/Perl-Return-Deep](https://github.com/CindyLinz/Perl-Return-Deep).
It's welcome to discuss with me when you encounter bugs, or
if you think that some patterns are also useful but the mod didn't provide them yet.

# AUTHOR

Cindy Wang (CindyLinz), <cindy@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2020 by Cindy Wang (CindyLinz)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.1 or,
at your option, any later version of Perl 5 you may have available.
