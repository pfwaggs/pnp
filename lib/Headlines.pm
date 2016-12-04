package Headlines;

# vim: ai si sw=4 sts=4 et
# vim: fdc=4 fmr=AAA,ZZZ fdm=marker

# some preamble stuff #AAA

use strict;
use warnings;
no warnings 'once';
use v5.22;
use experimental qw(postderef signatures smartmatch);
use Data::Printer;
use Path::Tiny;
use JSON;
#use HC::Transforms;
use HC::Stats;
use Date::Tiny;
use Sort::Key::Natural qw(natsort);

my $pkg = 'Headlines';
my %config;

#ZZZ

sub BuildHeadlines { #AAA
    my $year = Date::Tiny->now->year;
    my %headlines = ();
    my $JsonFile = 'Headines-'.$year.'.json';
    if (path($JsonFile)->is_file) {
        %headlines = JSON->new->utf8->decode(path($JsonFile)->slurp)->%*;
    }

    for my $file (map {"$_"} path('.')->children(qr/$year\d\d\.txt/)) {
        my ($month) = $file =~ /$year(\d\d)\.txt/;
        my $key = 'H-'.$year.'-'.$month;
        next if exists $headlines{$key};
        for my $line (path($file)->lines_utf8({chomp=>1})) {
            my ($msgkey, $val) = split /\.\s+/, $line, 2;
            $msgkey =~ s/^\s*|\s*$//g;
            $val    =~ s/^\s*|\s*$//g;
            $headlines{$key}{$msgkey}{msg}   = [$val];
            $headlines{$key}{$msgkey}{pairs} = "";
        }
    }
    path($JsonFile)->spew(JSON->new->utf8->pretty->encode(\%headlines));
} #ZZZ

sub Display ($msgs_h, $pairs_h, $stats_h) { #AAA
    my %msgs = $msgs_h->%*;
    my %pairs = $pairs_h->%*;
    my %stats = $stats_h->%*;
    print $HC::clear;
#   my ($max) = sort {$b <=> $a} map {length $msgs{$_}{msg}[0]} keys %msgs;
    for (sort keys %msgs) {
        my $order = HC::Utils::OrderKeys(\%config, $stats{$_}, $pairs{$_});
        say "\n";
        HC::UI::DisplayMsg($_, $msgs{$_}, $pairs{$_});
        HC::UI::DisplayStats($order, $stats{$_}) if $config{stats} eq 'yes';
        HC::UI::DisplayAlpha($config{letters}, $order, $pairs{$_});
#       say "\t" . '='x$max;
    }
} #ZZZ

sub Delete ($msgs_h) { #AAA
    my %msgs = $msgs_h->%*;
    my $reply = uc $HC::term->get_reply(prompt => 'provide a msg# followed by cipher letters to clear');
    my ($msg_key, @deletes) = split /\s+/, $reply;
    delete $msgs{$msg_key}{pairs}{$_} for @deletes;
    return wantarray ? %msgs : \%msgs;
} #ZZZ

sub Wipe ($msgs_h) { #AAA
    my %msgs = $msgs_h->%*;
    my $reply = uc $HC::term->get_reply(prompt => 'provide msg#(s) to wipe');
    my @deletes = split /\s+/, $reply;
    p @deletes;
    $msgs{$_}{pairs} = {} for @deletes;
    p %msgs;
    return wantarray ? %msgs : \%msgs;
} #ZZZ

sub InitMsg ($list_a) { #AAA
    my @strs = $list_a->@*;
    my %hash;
    for (@strs) {
        my ($key, $val) = split /\s*[[:punct:]]\s*/, $_, 2;
        $key =~ s/^\s*|\s*$//g;
        $val =~ s/^\s*|\s*$//g;
        $hash{$key}{msg} = ${val};
        $hash{$key}{pairs} = {};
    }
    return wantarray ? %hash : \%hash;
} #ZZZ

sub Save ($file, $msgs_h) { #AAA
    my %msgs = $msgs_h->%*;
    for my $msg (keys %msgs) {
        $msgs{$msg}{pairs} = join(' ',map {$_.$msgs{$msg}{pairs}{$_}} sort keys $msgs{$msg}{pairs}->%*);
    }
#   $msgs_h->{$_}{pairs} = join(' ',$msgs_h->{$_}{pairs}->%*) for keys $msgs_h->%*;
    my @ans = qw/yes no/;
    my $reply = $HC::term->get_reply(prompt=>'shall i save this? ', choices=>\@ans,);
    if ($reply =~ /^y/i) {
        path($file)->spew(JSON->new->utf8->pretty->encode($msgs_h));
    }
} #ZZZ

$HC::Solvers{Headline} = sub ($msgs_h) { #AAA
    %config = exists $HC::Configs{$pkg}
    ? $HC::Configs{$pkg}->%*
    : (HC::UI::Options(), package => $pkg);

    my %msgs = $msgs_h->%*;
    my @MonthKeys = natsort grep {/^H-/} keys %msgs;
    my @msg_menu = map {$_.' : '.$msgs{$_}{1}{msg}[0]} @MonthKeys;
    my %l_h = (prompt => 'choose a message', choices => [@msg_menu, 'quit']);
    {
        my $reply = $HC::term->get_reply(%l_h);
        last if $reply eq 'quit';
        my ($MonthKey) = split / : /, $reply;
        my %msg = $msgs{$MonthKey}->%*;
        my %stats;
        my %pairs;
        for (keys %msg) {
            $stats{$_} = {HC::Stats::Mono($msg{$_}{msg}->@*)};
            $pairs{$_} = defined $msg{$_}{pairs} ? {HC::Utils::Digraph2Hash($msg{$_}{pairs})} : {};
        }
#        for my $keyndx (keys %msg) {
#            $stats{$keyndx} = {HC::Stats::Mono($msg{$keyndx}{msg}->@*)};
#            $msg{$keyndx}{pairs} = defined $msg{$keyndx}{pairs_str} ? {HC::Utils::Digraph2Hash($msg{$keyndx}{pairs_str})} : {};
#            $msg{$keyndx}{pairs}{$_} = ' ' for grep {! exists $msg{$keyndx}{pairs}{$_}} keys $stats{$keyndx}{freqs}->%*;
#            $msg{$keyndx}{order} = [HC::Utils::OrderKeys($stats{$keyndx}, $msg{$keyndx}{pairs})];
#        }
        Display(\%msg, \%pairs, \%stats);
#       HC::UI::SaveConfig(%config) if $config{saveme}//0;
        return; # wantarray ? %msgs : \%msgs;
    }

#    my @actions = qw/Quit Add Delete Wipe/;
#    {
#        my $reply = $HC::term->get_reply(%l_h);
#        last if $reply eq 'quit';
#        my ($key) = split / : /, $reply;
#        my %msg = $msgs{$key}->%*;
#        $msg{stats} = {ACA::Stats::Mono($msg{msg}->@*)};
#        $msg{pairs} = defined $msg{pairs} ? {ACA::Utils::Digraph2Hash($msg{pairs})} : {};
#        $msg{pairs}{$_} = ' ' for grep {! exists $msg{pairs}{$_}} keys $msg{stats}{freqs}->%*;
#
#
#        Display(\%msgs);
#        my $reply = $HC::term->get_reply(
#            prompt => 'pick an action:',
#            choices => \@actions,
#            default => 'Add',
#        );
#        if ($reply eq 'Add') {
#            %msgs = Add(\%msgs);
#        } elsif ($reply eq 'Delete') {
#            %msgs = Delete(\%msgs);
#        } elsif ($reply eq 'Wipe') {
#            %msgs = Wipe(\%msgs);
#        } else {
#            # we must have quit
#            last;
#        }
#        redo;
#    }

    #Save($save_file, \%msgs);
    return wantarray ? %msgs : \%msgs;
};
#ZZZ

1;

__END__


#sub SaveConfig ($pkg, $config_h, $file='.hc.json') { #AAA
#    $file_obj = path("~/$file");
#    my $reply = $HC::term->ask_yn(
#        prompt => "shall i make this configuration the default for $pkg?",
#        default => 'y'
#    );
#    if ($reply) {
#        my %configall = JSON->new->utf8->decode($file_obj->slurp)->%*;
#        $configall{$pkg} = {$config_h->%*};
#        delete $configall{$pkg}{saveme};
#        $file_obj->spew(JSON->new->utf8->pretty->encode(\%configall))
#    }
#} #ZZZ

#sub Read ($input_file) { #AAA
#    my %rtn;
#    if ($input_file->stringify =~ /json$/) {
#        %rtn = JSON->new->utf8->decode($input_file->slurp)->%*;
#        $rtn{$_}{pairs} = {split //, $rtn{$_}{pairs}=~s/\s//gr} for keys %rtn;
#    } elsif ($input_file->stringify =~ /txt$/) {
#        my @tmp = $input_file->lines({chomp=>1});
#        %rtn = InitMsg(\@tmp);
#    } else {
#        die 'no valid txt or json file found', "\n";
#    }
#    return wantarray ? %rtn : \%rtn;
#} #ZZZ

#sub Guess ($pairs_h) { #AAA
#    my %pairs = $pairs_h->%*;
#    my %msgs = $msgs_h->%*;
#    my $reply = uc $HC::term->get_reply(prompt => 'provide a msg# followed by cipher plain pairs');
#    my ($msg_key, @pairs) = split /\s+/, $reply;
#    for (@pairs) {
#        my ($c, $p) = split //, $_;
#        $msgs{$msg_key}{pairs}{$c} = $p;
#    }
#    return wantarray ? %msgs : \%msgs;
#} #ZZZ

#sub Display ($msgs_h) { #AAA
#    print $HC::clear; # see previous comment about perl cookbook
#    my $g_alpha = join(' ', split(//, $HC::AlphaUpper));
#    my %msgs = $msgs_h->%*;
#    my ($max) = sort {$b <=> $a} map {length $msgs{$_}{msg}} keys %msgs;
#    my @chart = (' 'x5 . '='x$max);
#    push @chart, ' 'x5 . $g_alpha;
#    my @output;
#    for my $msg (sort keys %msgs) {
#        push @output, sprintf "%2s : %s", $msg, $msgs{$msg}{msg};
#        push @output, sprintf "%2s   %s\n", '', Transforms::Mono($msgs{$msg}{msg}, $msgs{$msg}{pairs}->%*);
#        push @chart, ' 'x5 . Transforms::Mono($g_alpha, $msgs{$msg}{pairs}->%*);
#    }
#    say for @output, @chart;
#} #ZZZ
