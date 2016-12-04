package HC::UI;

# vim: ai si sw=4 sts=4 et
# vim: fdc=4 fmr=AAA,ZZZ fdm=marker

use strict;
use warnings;
no warnings 'once';
use v5.22;
use experimental qw(signatures postderef smartmatch);

use Data::Printer;
use Path::Tiny;
use JSON::PP;
use HC::Transforms;

sub DisplayMsg ($msg_h, $pairs_h) { #AAA
    my %msg = $msg_h->%*;
    printf "\t%s\n\t%s\n\n", $_, HC::Transforms::Mono($_, $pairs_h) for $msg{msg}->@*;
} #ZZZ

sub DisplayMsg2 ($lead, $msg_h, $pairs_h) { #AAA
    my %msg = $msg_h->%*;
    printf "%-8s%s\n\t%s\n\n", "$lead : ", $_, HC::Transforms::Mono($_, $pairs_h) for $msg{msg}->@*;
} #ZZZ

sub DisplayStats ($order_a, $stat_h) { #AAA
    my @order = $order_a->@*;
    my %stat = $stat_h->%*;
    printf "%-6s%s\n", ' ', join('', map {sprintf "%3d", $stat{freqs}{$_}} @order);
} #ZZZ

sub DisplayAlpha ($letters, $order_a, $msg_h) { #AAA
    my @order = $order_a->@*;
    my %pairs = $msg_h->%*;
    my $keys = join('', map {sprintf "%3s", $_} @order);
    my $maps = join('', map {sprintf "%3s", $pairs{$_}} @order);
    $maps =~ s/[a-z]/ /g if $letters eq 'some';
    printf "%-6s%s\n", ' ', $keys;
    printf "%-6s%s\n", ' ', $maps;
} #ZZZ

#sub Display (%msg) { #AAA
#    print $HC::clear;
#    my $max = _DisplayMsg(%msg);
#    say "\t" . '='x$max;
#    my $pairs = ACA::Utils::OrderKeys($msg{stats}, $msg{pairs});
#    _DisplayStats($pairs, $msg{stats});
#    _DisplayAlpha($pairs, $msg{pairs});
#} #ZZZ

sub Guess (%pairs) { #AAA
    my $reply = $HC::term->get_reply(prompt => 'provide cipher->plain pairs');
    if (defined $reply and $reply =~ /^[a-zA-Z\s]+$/) {
        for (split /\s+/, uc $reply) {
            my ($c, $p) = split //, $_;
            $pairs{$c} = $p;
        }
    }
    return wantarray ? %pairs : \%pairs;
} #ZZZ

sub Options (%config) { #AAA
    my %Options = (
        letters => [qw/some all/],
        sort    => [qw/key val freq/],
        chart   => [qw/yes no/],
        stats   => [qw/no yes/],
    );
    if (keys %config) {
        {
            my %MenuMap = map {$_." ($config{$_})" => $_} grep {! /package|saveme/} keys %config;
            my @Menu = sort keys %MenuMap;
            my $reply = $HC::term->get_reply(
                prompt  => 'pick option',
                choices => [@Menu, 'quit'],
                default => 'quit',
            );
            last if $reply eq 'quit';
            $reply = $MenuMap{$reply};
            if (exists $config{$reply}) {
                my $val = $HC::term->get_reply(
                    prompt  => 'choose: ',
                    choices => [$Options{$reply}->@*],
                    default => $Options{$reply}[0],
                );
                $config{saveme} = 1 if $config{$reply} ne $val;
                $config{$reply} = $val;
            } else {
                $config{$reply} = $Options{$reply}[0];
            }
            redo;
        }
    } else {
        # if %config is empty then set defaults
        %config = map {$_ => $Options{$_}[0]} keys %Options;
    }
    return wantarray ? %config : \%config;
} #ZZZ

sub SaveConfig (%config) { #AAA
    my $pkg = $config{package};
    my $reply = $HC::term->ask_yn(
        prompt => "shall i make this configuration the default for $pkg?",
        default => 'y'
    );
    if ($reply) {
        my $file_obj = path("~/$HC::ConfigFile");
        my %Configs = JSON->new->utf8->decode($file_obj->slurp)->%*;
        $Configs{$pkg} = %config;
        delete $Configs{$pkg}{saveme};
        $file_obj->spew(JSON->new->utf8->pretty->encode(\%Configs))
    }
} #ZZZ

sub Erase (%pairs) { #AAA
    my $reply = uc $HC::term->get_reply(prompt => 'provide plain keys (or "all") to clear');
    my @wipe = $reply =~ /all/i ? ('A'..'Z') : split(//, $reply);
    $pairs{$_} = lc $_ for @wipe;
    return wantarray ? %pairs : \%pairs;
} #ZZZ

1;
