package HC::Utils;

# vim: ai si sw=4 sts=4 et
# vim: fdc=4 fmr=AAA,ZZZ fdm=marker 

use strict;
use warnings;
use v5.22;
use experimental qw(signatures postderef smartmatch);
use Data::Printer;
use List::AllUtils qw(uniq);

sub OrderKeys ($config_h, $MsgStats_h, $MsgPairs_h) { #AAA
    my %config = $config_h->%*;
    my %MsgStats = $MsgStats_h->%*;
    my %MsgPairs = $MsgPairs_h->%*;
    my @keys;
    if ($config{sort} eq 'freq') {
        @keys = sort {$MsgStats{freqs}{$b} <=> $MsgStats{freqs}{$a}} keys $MsgStats{freqs}->%*;
    } elsif ($config{sort} eq 'key') {
        @keys = sort keys %MsgPairs;
    } else {
        @keys = sort {$MsgPairs{$a} cmp $MsgPairs{$b}} keys %MsgPairs;
    }
    return wantarray ? @keys : \@keys;
} #ZZZ

sub Digraph2Hash ($str) { #AAA
    my %rtn = (split //, $str=~s/\s//gr);
    $rtn{$_} = lc $_ for grep {! exists $rtn{$_}} ('A'..'Z');
    return wantarray ? %rtn : \%rtn;
} #ZZZ

sub Hash2Digraph ($hash_h) { #AAA
    my %hash = $hash_h->%*;
    delete $hash{$_} for grep {$hash{$_} =~ /\s/} keys %hash;
    return join ' ', map {$_.$hash{$_}} grep {$hash{$_} =~ /[A-Z]/} keys %hash;
} #ZZZ

sub ExtractColumns ($str, %order) { #AAA
    my $mod = keys %order;
    $str .= '.' while length($str) % $mod;
    my @list = split //, $str;
    my %rtn;
    while (my($ndx, $val) = each (@list)) {
        $rtn{$order{1 + $ndx % $mod}} .= $val;
    }
    return wantarray ? %rtn : \%rtn;
} #ZZZ

sub IndexedKeyWord ($word) { #AAA
    # first we order the letters left to right
    my $count = 0;
    my @list;
    push @list, map {sprintf "%s%02d", $_, $count++} split //, $word;	
    # make a hash from the sorted list
    $count = 1;
    my %hash = map {$_=>$count++} sort @list;
    # want values ordered by list
    my @rtn = @hash{@list};
    my %rtn;
    while ( my ($ndx, $val) = each(@rtn)) {
        $rtn{1+$ndx} = $val;
    }
    return wantarray ? %rtn : \%rtn;
} #ZZZ

sub Decimate ($length, $columns) { #AAA
    my $val = 1;
    my @rtn = ();
    if ($length % $columns) {
        while (@rtn < $columns) {
            if ($val <= $columns && ! ($val ~~ @rtn)) {
                push @rtn, $val;
            }
            $val += $columns;
            $val -= $length if $length < $val;
        }
    } else {
        push @rtn, (1 .. $columns);
    }
    return wantarray ? @rtn : \@rtn;
} #ZZZ

sub Dedupe {
    return List::AllUtils::uniq(split //, join '', @_);
}

# Dedupe should probably be replaced with List::AllUtils::uniq.
sub _Dedupe { #AAA
    my @list = split //, join '', @_;
    my @short_list;
    for my $a (@list) {
	(grep {/$a/} @short_list) ? next : push(@short_list,$a);
    }
    return join('',@short_list);
} # ZZZ

# Decimate 
#sub Decimate { #AAA
#    my @chars = split //, shift;
#    my $op = shift;
#    my $width;
#    my @order;
#    if ($op =~ /\d/) {
#	$width = $op;
#	@order = (0..$op-1);
#    } else {
#	$width = length $op;
#	my $count = 0;
#	my %hash = map {$count++=>$_} Numberfy($op);
#	%hash = reverse %hash;
#	@order = @hash{sort {$a<=>$b} keys %hash};
#    }
#    my @rtn = (('')x$width);
#    my $pos = 0;
#    my $index = $pos;
#    while (grep {/\w/} @chars) {
#	$rtn[$index] .= $chars[$pos];
#	$chars[$pos] = ' ';
#    } continue {
#	$pos += $width;
#	if ($pos >= @chars) {
#	    $index = $pos %= @chars;
#	}
#	if ($pos < @chars and $chars[$pos] eq ' ') {
#	    $pos++;
#	    $index = $pos %= @chars;
#	}
#    }
#    @rtn = @rtn[@order];
#    return wantarray ? @rtn : \@rtn;
#} #ZZZ

# On_width 
sub On_width { #AAA
    my $str = shift;
    my $width = shift;
    $width = length $width unless $width =~ /\d/;
    my @rows = split /\s/, $str =~ s/(.{$width})/$1 /gr;
    return wantarray ? @rows : \@rows;
} #ZZZ

## Aca_password
#sub Aca_password { #AAA
#    my $jpp_in = JSON::PP->new->utf8;
#    my %msgs = %{$jpp_in->decode(join(' ',path(shift)->lines({chomp=>1})))};
#    my $str = lc substr($msgs{A}{1}{msg}[0] =~ s/\W//gr,0,7).'1';
#    return $str;
#} #ZZZ

#sub mo2 { #AAA
#    my @aoa = @{shift @_};
#    my %max;
#    # we convert entries in 2d matrix to lengths of the entries
#    for my $row (@aoa) {
#	while (my ($ndx, $val) = each (@$row)) {
#	    push @{$max{$ndx}}, length $val;
#	}
#    }
#    # over all the columns find the maximal element for that column
#    $max{$_} = pop [sort {$a <=> $b} @{$max{$_}}] for keys %max;
#    # adjust each element in the original matrix to fit in the maximal size
#    # for that column
#    for my $row (@aoa) {
#	while (my ($ndx, $val) = each (@$row)) {
#	    $val = sprintf "%*s", $max{$ndx}, $val;
#	    $row->[$ndx] = $val;
#	}
#    }
#    return @aoa;
#} #ZZZ

#sub read_Json { #AAA
#    my $json = JSON::PP->new->utf8;
#    my $str = join(' ', path(shift)->lines({chomp=>1}));
#    $str = $json->decode($str);
#    my $ref = ref $str;
#    if ($ref eq 'HASH') {
#	return wantarray ? %$str : $str;
#    } elsif ($ref eq 'ARRAY') {
#	return wantarray ? @$str : $str;
#    } else {
#	return $str;
#    }
#} #ZZZ

#sub write_Json { #AAA
#    my $json = JSON::PP->new->utf8;
#    push my @str, $json->pretty->encode(shift);
#    path(shift)->spew(@str);
#} #ZZZ


1;
