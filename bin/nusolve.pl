#!/usr/bin/env perl

# vim: ai si sw=4 sts=4 et fdc=4 fmr=AAA,ZZZ fdm=marker

# normal junk #AAA
use warnings;
use strict;
use v5.22;
use experimental qw(postderef signatures smartmatch);

use Getopt::Long qw( :config no_ignore_case auto_help );

use Path::Tiny;
use JSON;
use Data::Printer;
use Term::UI;
use Sort::Key::Natural qw(natsort);

use HC;

#ZZZ

my $file = shift or die 'no input file given', "\n";
die 'problem with the file '.$file, "\n" unless path($file)->is_file;
my %FileContents = JSON->new->utf8->decode(path($file)->slurp)->%*;
my @FileKeys = natsort keys %FileContents;
my %FamilyGlobs = map {my $l = substr(uc $_,0,1); qr/$l-/ => $_} keys %HC::Solvers;
my @FamilyKeys = grep {/$_/ ~~ @FileKeys} keys %FamilyGlobs;
my $family = 1 == @FamilyKeys ? $FamilyKeys[0] : $HC::term->get_reply(prompt => 'pick family type', choices => \@FamilyKeys);
$family = $FamilyGlobs{$family};

my %State = $HC::Solvers{$family}(\%FileContents);

