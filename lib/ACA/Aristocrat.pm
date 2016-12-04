package ACA::Aristocrat;

# vim: ai si sw=4 sts=4 et
# vim: fdc=4 fmr=AAA,ZZZ fdm=marker

# some preamble stuff #AAA
use warnings;
no warnings 'once';
use strict;
use v5.22;
use experimental qw(postderef signatures smartmatch);
use Data::Printer;
use Path::Tiny;
use JSON;

use Sort::Key::Natural qw(natsort);
use Term::UI;

## from perl cookbook..................................+
#use Term::Cap;                                        #
#my $OSPEED = 9600;                                    #
#eval {                                                #
#    require POSIX;                                    #
#    my $termios = POSIX::Termios->new();              #
#    $termios->getattr;                                #
#    $OSPEED = $termios->getospeed;                    #
#};                                                    #
#my $terminal = Term::Cap->Tgetent({OSPEED=>$OSPEED}); #
#my $clear = $terminal->Tputs('cl', 1, *STDERR);       #
##.....................................................+

#use HC::Transforms;
use HC::Stats;
use HC::Utils;

my $pkg = 'Aristocrats';
my %config;

#ZZZ

sub Save ($file, %msgs) { #AAA
    my @keep = qw/msg pairs solved state keys/;
    my %save;
    $save{$_} = {$msgs{$_}->%{@keep}} for keys %msgs;
    my %l_h = (prompt => 'shall i save this session?', default => 'y');
    path($file)->spew(JSON->new->utf8->pretty->encode(\%save)) if $HC::term->ask_yn(%l_h);
} #ZZZ

sub Keys () { #AAA
    my %rtn;
    {
        my @menu = qw/plain cipher setting/;
        my $reply = $HC::term->get_reply(
            prompt => 'what to set?',
            choices => [qw/plain_key cipher_key setting quit/],
            default => 'quit',
        );
        last if $reply eq 'quit';
        $rtn{$reply} = $HC::term->get_reply(prompt => 'enter text');
        redo;
    }
    return wantarray ? %rtn : \%rtn;

} #ZZZ

sub Display ($msg_h, $pairs_h, $stats_h) { #AAA
#   my %msg = $msg_h->%*;
#   my %pairs = $pairs_h->%*;
#   my %stats = $stats_h->%*;
    print $HC::clear;
    HC::UI::DisplayMsg($msg_h, $pairs_h);
    #say "\t" . '='x$max;
    my $order = HC::Utils::OrderKeys(\%config, $stats_h, $pairs_h);
    HC::UI::DisplayStats($order, $stats_h) if $config{stats} eq 'yes';
    HC::UI::DisplayAlpha($config{letters}, $order, $pairs_h);
} #ZZZ

$HC::Solvers{Aristocrat} = sub ($msgs_h) { #AAA
    %config = exists $HC::Configs{$pkg}
    ? $HC::Configs{$pkg}->%*
    : (HC::UI::Options(), package => $pkg);

    my %msgs = $msgs_h->%*;
    my @msg_keys = grep {/^A-/} natsort keys %msgs;  # dervied from first letter of family name
    my @msg_menu = map {$_.' : '.$msgs{$_}{msg}[0]} @msg_keys;
    my %l_h = (prompt => 'choose a message', choices => [@msg_menu, 'quit']);
    {
        my $reply = $HC::term->get_reply(%l_h);
        last if $reply eq 'quit';
        my ($key) = split / : /, $reply;
        my %msg = $msgs{$key}->%*;
        my %stats = HC::Stats::Mono($msg{msg}->@*);
        my %pairs = defined $msg{pairs} ? HC::Utils::Digraph2Hash($msg{pairs}) : ();

        {
            Display(\%msg, \%pairs, \%stats);
            my $reply = $HC::term->get_reply(
                prompt => 'pick an action:',
                choices => [qw/Guess Erase Keys Options Quit/],
                default => 'Guess',
            );
            if ($reply eq 'Quit') {
                last;
            } elsif ($reply eq 'Options') {
                %config = HC::UI::Options(%config);
            } elsif ($reply eq 'Keys') {
                $msg{keys} = HC::UI::Keys();
            } elsif ($reply eq 'Erase') {
                %pairs = HC::UI::Erase(%pairs);
            } else {
                %pairs = HC::UI::Guess(%pairs);
            }
            redo;
        }
        $msgs{$key}{pairs} = HC::Utils::Hash2Digraph(\%pairs);
    }
    HC::UI::SaveConfig(%config) if $config{saveme}//0;
    return wantarray ? %msgs : \%msgs;
}; #ZZZ

1;

__END__

# to be removed  in future #AAA
#sub _DisplayMsg (%msg) { #AAA
#    my ($max) = sort {$b <=> $a} map {length $_} $msg{msg}->@*;
#    say "\n";
#    printf "\t%s\n\t%s\n\n", $_, Transforms::Mono($_, $msg{pairs}) for $msg{msg}->@*;
#    return $max;
#} #ZZZ
#sub _DisplayAlpha ($pairs_a, $MsgPairs_h) { #AAA
#    my @pairs = $pairs_a->@*;
#    my %MsgPairs = $MsgPairs_h->%*;
#    say join ' ', map {sprintf "%3s", $_} @pairs;
#    say join ' ', map {sprintf "%3s", $MsgPairs{$_}} @pairs;
#} #ZZZ
#sub Display (%msg) { #AAA
#    print $HC::clear;
#    my $max = _DisplayMsg(%msg);
#    say "\t" . '='x$max;
#    my $pairs = ACA::Utils::OrderKeys($msg{stats}, $msg{pairs});
#    _DisplayStats($pairs, $msg{stats});
#    _DisplayAlpha($pairs, $msg{pairs});
#} #ZZZ
#sub Guess (%pairs) { #AAA
#    for (split /\s+/, uc $HC::term->get_reply(prompt => 'provide cipher->plain pairs')) {
#        my ($c, $p) = split //, $_;
#        $pairs{$c} = $p;
#    }
#    return wantarray ? %pairs : \%pairs;
#} #ZZZ
#ZZZ

#sub Erase (%pairs) { #AAA
#    my $reply = uc $HC::term->get_reply(prompt => 'provide plain keys (or "all") to clear');
#    my @wipe = $reply =~ /all/i ? ('A'..'Z') : split(//, $reply);
#    $pairs{$_} = ' ' for @wipe;
#    return wantarray ? %pairs : \%pairs;
#} #ZZZ

#my #%dispatch = ( #AAA
#
#    actions => [ qw/Guess Erase/ ],
#
## do we need these? #AAA
#
##    OrderKeys => sub ($MsgStats_h, $MsgPairs_h) { #AAA
##        my %MsgStats = $MsgStats_h->%*;
##        my $MsgPairs = $MsgPairs_h->%*;
##        my @keys;
##        if ($g_config{stats}{sort_freq}) {
##            @keys = sort {$MsgStats{freqs}{b} <=> $MsgStats{freqs}{a}} keys $MsgStats{freqs}->%*;
##        } elsif ($g_config{pairs}{sort_keys}) {
##            @keys = sort keys %MsgPairs;
##        } else {
##            @keys = sort {$MsgPairs{$a} cmp $MsgPairs{$b}} keys %MsgPairs;
##        } 
##        return wantarray ? @keys : \@keys;
##    }, #ZZZ
#
##    Wipe => sub (%msg) { #AAA
##        $msg{pairs}{$_} = ' ' for keys $msg{pairs}->%*;
##        return wantarray ? %msg : \%msg;
##    }, #ZZZ
#
##    Read => sub ($input_file) {#AAA
##        my %rtn;
##        if ($input_file->stringify =~ /json$/) {
##            %rtn = JSON->new->utf8->decode($input_file->slurp)->%*;
##            $rtn{$_}{pairs} = {split //, $rtn{$_}{pairs}=~s/\s//gr} for keys %rtn;
##        } elsif ($input_file->stringify =~ /txt$/) {
##            my @tmp = $input_file->lines({chomp=>1});
##            %rtn = $dispatch{InitMsg}(\@tmp);
##        } else {
##            die 'no valid txt or json file found', "\n";
##        }
##        return wantarray ? %rtn : \%rtn;
##    }, #ZZZ
#
##    InitMsg => sub ($list_a) {#AAA
##        my @strs = $list_a->@*;
##        my %hash;
##        for (@strs) {
##            my ($key, $val) = split /\s*[[:punct:]]\s*/, $_, 2;
##            $key =~ s/^\s*|\s*$//g;
##            $val =~ s/^\s*|\s*$//g;
##            $hash{$key}{msg} = ${val};
##            $hash{$key}{pairs} = {};
##        }
##        return wantarray ? %hash : \%hash;
##    }, #ZZZ
##ZZZ
#
#); #ZZZ
