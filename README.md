# NAME

Return::Deep - deeply returns through multiple layers at once

# SYNOPSIS

    use Return::Deep;

    sub a {
      b();
    }

    sub b {
      deep_ret(2, 'Hi', 42);
    }

    my @ret = a();
    # got ('Hi', 42) here

# DESCRIPTION

Deeply returns through multiple layers at once.

## EXPORT

- deep\_ret($depth, @return\_value)

    If `$depth` = 1, it performs like a normal return.

    If `$depth` <= 0, it performs like a normal list.

    If `$depth` > 1, it returns through many layers, including subs and eval blocks.

Tested on Perl version perl-5.30.2, perl-5.28.2, perl-5.26.3, perl-5.24.4, perl-5.22.4, perl-5.20.3, perl-5.18.4, perl-5.16.3, perl-5.14.4, perl-5.12.5, perl-5.10.1, perl-5.8.9.

# SEE ALSO

This mod's github [https://github.com/CindyLinz/Perl-Deep-Return](https://github.com/CindyLinz/Perl-Deep-Return).
It's welcome to discuss with me when you encounter bugs, or
if you think that some patterns are also useful but the mod didn't provide them yet.

# AUTHOR

Cindy Wang (CindyLinz), <cindy@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2020 by Cindy Wang (CindyLinz)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.1 or,
at your option, any later version of Perl 5 you may have available.
