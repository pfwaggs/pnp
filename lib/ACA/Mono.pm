package Ciphers::Mono;

use strict;
use warnings;
use v5.22;
use experimental qw(signatures postderef);
use Data::Printer;
#use Path::Tiny;
#use JSON::PP;

use Stats;
use Menu;
#use Setup;

# parse_action AAA
sub parse_action {
    my %checks = %{shift @_};
    my $my_action   = 1 - ($checks{action} =~ s/quit//);
    if ($checks{action} =~ s/(number|alpha)//) {
	$checks{stat_order} = $1;
    }
    if ($checks{action} =~ s/solved//) {
	$checks{solved} = 1;
	$my_action = 0; 
    }
    if ($checks{action} =~ s/stats//) {
	$checks{show_stats} = 1 - $checks{show_stats};
    }
    if ($checks{action} =~ s/flip//) {
	$checks{flip} = 1 - $checks{flip};
    }
    $checks{action} =~ s/^\s+|\s+$//g; # remove leading/trailing spaces
    if ($checks{action}) {
	for (split /:/, $checks{action}) {
	    next unless length $_ le 2;
	    my ($f, $s) = split //, uc $_;
	    $checks{state}{$f} = $s =~ /\w/ ? $s : ' ';
	}
    }
    $checks{action} = $my_action;
    return wantarray ? %checks : \%checks;
}
#ZZZ

# monosubstitution AAA
sub monosubstitution {
    my %data = %{shift @_};
    my $CIPHER = join('', keys $data{state})//'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    my $plain = lc join('', values $data{state})//'abcdefghijklmnopqrstuvwxyz';

    my @rtn;
    for (@{$data{msg}}) {
	my $line = $_;
	eval "\$line =~ tr/$CIPHER/$plain/" if $CIPHER;
	$line =~ s/[[:upper:]]/ /g;
	eval "\$line =~ tr/$plain/\U$plain/" if $plain;
	push @rtn, $line;
    }
    return wantarray ? @rtn : \@rtn;
}
#ZZZ

# commands AAA

my %commands;
%commands = (

# order AAA
    order => sub {
	my %in = %{shift @_};
	$in{order} = $in{option};
	my %t = $in{order} eq 'key' ? %{$in{key}} : %{$in{val}};
	my @a = sort keys %t;
	my @b = @t{@a};
	@in{qw/top bottom/} = $in{order} eq 'key' ? ([@a], [@b]) : ([@b], [@a]);
	return wantarray ? %in : \%in;
    },
#ZZZ

# rev AAA
    rev => sub {
	my %in = %{shift @_};
	$in{top} = [reverse @{$in{top}}];
	$in{bottom} = [reverse @{$in{bottom}}];
	return wantarray ? %in : \%in;
    },
#ZZZ

# slide AAA
    slide => sub {
	my %in = %{shift @_};
	my %t = $in{order} eq 'key' ? %{$in{key}} : %{$in{val}};
	my @a = sort keys %t;
	my @b = @t{@a};
	while ($b[0] ne uc $in{option}) { # a little tricky here; a is the sorted list so b probably has the keyword
	    push @a, $a[0]; shift @a;
	    push @b, $b[0]; shift @b;
	}
	@in{qw/top bottom/} = $in{order} eq 'key' ? ([@a], [@b]) : ([@b], [@a]);
	return wantarray ? %in : \%in;
    },
#ZZZ

# insert AAA
    insert => sub {
	my %in = %{shift @_};
	for (split /:/, uc $in{option} =~ s/^\s*|\s*$//gr) {
	    my ($key, $val) = split //, $_, 2;
	    $in{key}{$key} = $val;
	    $in{val}{$val} = $key;
	}
	$in{option} = $in{order};
	%in = $commands{order}(\%in);
	return wantarray ? %in : \%in;
    },
#ZZZ

# keywords AAA
    keyword => sub {
	my %in = %{shift @_};
	push @{$in{keywords}}, uc $in{option};
	return wantarray ? %in : \%in;
    },
#ZZZ

);
#ZZZ

# monoalphabetic_key_recovery AAA
sub monoalphabetic_key_recovery {
    my %msg = %{shift @_};
    my %bob = $commands{order}({option => 'key', key => $msg{state}, val => {reverse %{$msg{state}}}});

    my $commands_regex = join('|', map {"($_)"} ('quit', keys %commands));
    $commands_regex = qr/$commands_regex/;
    while (1) {
  	system('clear');
	say "order = $bob{order}";
	say join(' ', 'key :', @{$bob{top}});
	say join(' ', 'val :', @{$bob{bottom}});
	if (exists $bob{keywords}) {
	    say 'keywords :';
	    say "\t$_" for @{$bob{keywords}};
	}
	print "command? ";
	chomp(my $reply = <STDIN>);
	$reply =~ s/\b($commands_regex)\b//;
	my $cmd = $1;
	last if $cmd eq 'quit';
	next unless exists $commands{$cmd};
	$bob{option} = $reply =~ s/^\s*|\s*$//r;
	%bob = $commands{$cmd}(\%bob);
    }
    print "update? ";
    chomp(my $reply = <STDIN>);
    $bob{update} = $reply =~ /^y/i;
    if ($bob{update} and exists $bob{keywords}) {
	$msg{keywords} = [@{$bob{keywords}}];
	$msg{update} = 1;
    }
    return wantarray ? %msg : \%msg;
}
#ZZZ

## delete this later #AAA
#
### _monoalphabetic_display_text AAA
##sub _monoalphabetic_display_text {
##    my $flip = shift;
##    my @top; my @bot;
##    if ($flip) {
##	@bot = @{shift @_};
##	@top = @{shift @_};
##    } else {
##	@top = @{shift @_};
##	@bot = @{shift @_};
##    }
##    while (my ($ndx, $top) = each @top) {
##	say $top;
##	say $bot[$ndx];
##	say '';
##    }
##}
###ZZZ
#
### _monoalphabetic_display AAA
##sub _monoalphabetic_display {
##    my %config      = %{shift @_};
##    my %stats       = %{shift @_};
##    my @msg_encrypt = @{shift @_};
##    my @msg_decrypt = monosubstitution({state=>$config{state}, msg=>[@msg_encrypt]});
##
##    say join(' ', @{$stats{$config{stat_order}}{vals}}) if $config{show_stats};
##    my $fake_msg_encrypt = join(' ',@{$stats{$config{stat_order}}{keys}}); # fake_msg are the keys to stats
##    my $fake_msg_decrypt = join(' ',monosubstitution({state=>$config{state}, msg=>[$fake_msg_encrypt]})); # decrypt the generated fake message
##    _monoalphabetic_display_text($config{flip}, [$fake_msg_encrypt], [$fake_msg_decrypt]);
##    say '';
##    _monoalphabetic_display_text($config{flip}, \@msg_encrypt, \@msg_decrypt)
##}
###ZZZ
#
### monoalphabetic_plaintext_recovery AAA
##sub monoalphabetic_plaintext_recovery {
##    my %msg = @_;
##    $msg{update} = 0;
##    my %bob = (stat_order=>'alpha', show_stats=>1, action=>1, flip=>0, solved=>$msg{solved});
##    $bob{state} = defined $msg{state} ? $msg{state} : {};
##    my @msg_encrypt = @{$msg{msg}}; #$bob{msg} = $msg{msg};
##    my %stats = Stats::build_stat_indices($msg{stats}//{});
##
##    while ($bob{action} and ! $bob{solved}) {
##	system('clear');
##	_monoalphabetic_display(\%bob, \%stats, \@msg_encrypt);
##	print "encrypt/decrypt pair? ";
##	chomp($bob{action}=<STDIN>);
##	%bob = parse_action(\%bob);
##    }
##    $bob{action} = 'yes';
##    if (! $bob{solved}) {
##	print "save msg? ";
##	chomp($bob{action}=<STDIN>);
##    }
##    if ($bob{action} =~ /^y/i) {
##	$msg{solved} = $bob{solved};
##	$msg{state} = $bob{state};
##	$msg{update} = 1;
##    }
##    return wantarray ? %msg : \%msg;
##}
###ZZZ
##ZZZ

# new_mono_sub AAA
sub new_mono_sub {
    my %config = %{shift @_};
    my %msg = %{shift @_};
    my $encrypt = join('', keys $msg{state})//'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    my $decrypt = lc join('', values $msg{state})//'abcdefghijklmnopqrstuvwxyz';

    my @rtn;
    for (@{$msg{msg}}) {
	my $line = $_;
	eval "\$line =~ tr/$encrypt/$decrypt/";
	$line =~ s/[[:upper:]]/ /g;
	eval "\$line =~ tr/$decrypt/\U$decrypt/";
	push @rtn, $line;
    }
    return wantarray ? @rtn : \@rtn;
}
#ZZZ

# mono_Message_display #AAA
sub mono_Message_display {
    my @decrypt = new_mono_sub(@_);
    my %config = %{shift @_};
    my %msg = %{shift @_};
    my @top    = $config{top_line} eq 'decrypt' ? @decrypt     : @{$msg{msg}};
    my @bottom = $config{top_line} eq 'decrypt' ? @{$msg{msg}} : @decrypt;
    while (my ($ndx, $val) = each (@top)) {
	say $val;
 	say $bottom[$ndx];
    }
    say '';
}
#ZZZ

# mono_Stat_display #AAA
sub mono_Stat_display {
    my %config = %{shift @_};
    my %msg = %{shift @_};
    my @order = Stats::get_Stat_order(\%config, $msg{stats});

    say join(' ', map {sprintf "%2s", $_} @{$msg{stats}{freqs}}{@order});
    say join(' ', map {sprintf "%2s", $_} @order);
    say '';
}
#ZZZ

# mono_Recovery_display #AAA
sub mono_Recovery_display {
    my %config = %{shift @_};
    my %msg = %{shift @_};
    my @order = Stats::get_Stat_order(\%config, $msg{stats});
    my @top    = $config{top_line} eq 'decrypt' ? @{$msg{state}}{@order} : @order;
    my @bottom = $config{top_line} eq 'decrypt' ? @order : @{$msg{state}}{@order};
    say join(' ', map {sprintf "%2s", $_} @top);
    say join(' ', map {sprintf "%2s", $_} @bottom);
    say '';
}
#ZZZ

# monoalphabetic_solver AAA
sub monoalphabetic_solver {
    my %msg = @_;

    $msg{stats} = {Stats::mono_stats($msg{msg})} unless exists $msg{stats};

    while (1) {
	my @work_menu = qw/plaintext key/;
	#my ($work) = Menu::pick({header=>'which would you like to recover? '}, @work_menu);
	my $work = Menu::simple('which would you like to recover? ', @work_menu);
	last if $work < 0;
	my %update = $work ? monoalphabetic_key_recovery(%msg) : monoalphabetic_plaintext_recovery(%msg);
	if ($update{update}) {
	    delete $update{update};
	    %msg = %update;
	}
    }
    return wantarray ? %msg : \%msg;
}
#ZZZ

sub mono {
    my %config = %{shift @_};
    my %msg = %{shift @_};
    $msg{stats} = {Stats::mono_Stats($msg{msg})} unless exists $msg{stats};

    if (! exists $msg{state}) {
	$msg{state} = {map {$_ => ' '} keys %{$msg{stats}{freqs}}};
    }

    {
	system('clear');
	mono_Stat_display(\%config, \%msg);
	mono_Recovery_display(\%config, \%msg);
	mono_Message_display(\%config, \%msg);
	print "> ";
	chomp(my $input=<STDIN>);
	my %parsed_input = mono_Parse_input($input);
#take care of subs, config changes, key guesses
	$parsed_input{action} eq 'again' ? redo : last;
    }
}

# next task !!!!!!!!!!!!!!#AAA
sub headline_display {
    my %data = %{shift @_};
    p %data;
    for (sort keys %data) {
	say join(' : ', $_, @{$data{$_}{msg}});
    }
}

sub headline_solver {
    my %data = %{shift @_};
    headline_display(\%data);
}
#ZZZ

1;
