package HC::Stats;

# vim: ai si sw=4 sts=4 et
# vim: fdc=4 fmr=AAA,ZZZ fdm=marker

use strict;
use warnings;
use v5.22;
use experimental qw(postderef signatures smartmatch);

use Data::Printer;
use Path::Tiny;
use JSON::PP;
use Sort::Key::Natural qw(natsort);

sub _ic (%freqs) { #AAA
    my $sum_prod = 0;
    my $total = 0;
    for (keys %freqs) {
	$sum_prod += $freqs{$_}*($freqs{$_}-1);
	$total += $freqs{$_};
    }
    my %rtn = (sum_prod => $sum_prod, total => $total, value => (26 * $sum_prod / ($total*($total-1))));
    return wantarray ? %rtn : \%rtn;
}
#ZZZ

#our $GetOrder = sub ($order, %freq) { #AAA
#    my @rtn;
#    if ($order eq 'alpha') {
#        @rtn = sort keys %freq;
#    } else {
#        #@rtn = map {s/\d+\.//;chr($_)} sort {$b <=> $a} map {"$freq{$_}.".ord($_)} keys %freq;
#        @rtn = map {s/[\d]//gr} natsort map {$_.$freq{$_}} keys %freq;
#    }
#    return @rtn;
#}; #ZZZ

sub Mono (@lines) { #AAA
    my %counts;
    for my $line (map {s/\W//gr} @lines) {
        $counts{$_}++ for split //, $line;
    }
    $counts{$_} = 0 for grep {! exists $counts{$_}} ('A'..'Z');
    my %ic = _ic(%counts);
    my %rtn = (freqs => \%counts, ic => \%ic);
    return wantarray ? %rtn : \%rtn;
}; #ZZZ

#sub show_mono_stats_old { # deprecated #AAA
#    my %stats = %{shift @_};
#    my $order = shift;
#    my @order;
#    if ($order eq 'alpha') {
#	@order = sort keys %{$stats{freqs}};
#    } else { #for now this is only numerical
#	my %mono = %{$stats{freqs}};
#	@order = map {s/\d+\.//;chr($_)} sort {$b <=> $a} map {"$mono{$_}.".ord($_)} keys %mono;
#    }
#    my @rtn;
#    push @rtn, join(' ',map {sprintf "%2s", $_} @{$stats{freqs}}{@order});
#    push @rtn, join(' ',map {sprintf "%2s", $_} @order);
#    return wantarray ? @rtn : \@rtn;
#}
##ZZZ

#our %Stats = ( #AAA
#    Mono => \&_mono,
#    GetOrder => \&_getorder,
#);
##ZZZ

1;
