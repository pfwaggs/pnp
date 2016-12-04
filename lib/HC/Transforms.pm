package HC::Transforms;

# vim: ai si sw=4 sts=4 et
# vim: fdc=4 fmr=AAA,ZZZ fdm=marker

use warnings;
use strict;
use v5.22;
use experimental qw(postderef signatures smartmatch);

use Data::Printer;


sub Mono ($txt, $pairs_h) { #AAA
    my %pairs = $pairs_h->%*;
    my @rtn;
    my $plain = join '', values %pairs;
    my $cipher  = lc join '', keys %pairs;
    $txt = lc $txt;
    eval "\$txt =~ tr/$cipher/$plain/";
    $txt =~ s/[[:lower:]]/ /g;
    return $txt;
} #ZZZ

1;
