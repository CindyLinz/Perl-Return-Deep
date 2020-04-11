package Return::Deep;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (all => [ qw(deep_ret sym_ret ret_bound) ]);
our @EXPORT_OK = @{$EXPORT_TAGS{all}};
our @EXPORT = @{$EXPORT_TAGS{all}};

our $VERSION = '1.002';

require XSLoader;
XSLoader::load('Return::Deep', $VERSION);

sub ret_bound(&;$) {
    my($act, $symbol) = @_;
    my $guard = add_bound($act, $symbol);
    $act->();
}

1;
__END__

=head1 NAME

Return::Deep - deeply returns through multiple layers at once

=head1 SYNOPSIS

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
      my @inner_ret = ret_bound {
          if( .5 < rand ) {
              sym_ret('inner', 43); # @inner_ret got 43
          }
          else {
              sym_ret('any', 43); # @outer_ret got 44
          }
      } 'inner'; # catch 'inner'
  }; # catch all symbols without a catch symbol


=head1 DESCRIPTION

Deeply returns through multiple layers at once.

=head2 EXPORT

=over 4

=item deep_ret($depth, @return_value)

If C<$depth> = 1, it performs like a normal return.

If C<$depth> <= 0, it performs like a normal list.

If C<$depth> > 1, it returns through many layers, including subs and eval blocks.

=item sym_ret($symbol, @return_value)

Return through many layers, until the C<$symbol> is catched by a matched C<ret_bound>.

=item ret_bound {CODE_BLOCK} $catch_symbol

=item ret_bound {CODE_BLOCK}

Catch matched C<sym_ret>s. Without the C<$catch_symbol>, it will catch all the C<sym_ret>.

=back

Tested on Perl version 5.30.2, 5.28.2, 5.26.3, 5.24.4, 5.22.4, 5.20.3, 5.18.4, 5.16.3, 5.14.4, 5.12.5, 5.10.1, 5.8.9.


=head1 SEE ALSO

This mod's github L<https://github.com/CindyLinz/Perl-Return-Deep>.
It's welcome to discuss with me when you encounter bugs, or
if you think that some patterns are also useful but the mod didn't provide them yet.

=head1 AUTHOR

Cindy Wang (CindyLinz), E<lt>cindy@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Cindy Wang (CindyLinz)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
