package HC;

use strict;
use warnings;
use v5.22;
use experimental qw(signatures postderef smartmatch);
use JSON;
use Path::Tiny;
use Data::Printer;


use Term::UI;
our $term = Term::ReadLine->new($ENV{TERM});

our %Solvers;
our $AlphaLower = 'abcdefghijklmnopqrstuvwxyz';
our $AlphaUpper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
our $ConfigFile = path("~/.hc.json");
our %Configs = JSON->new->utf8->decode($ConfigFile->slurp)->%*;
$ConfigFile = $ConfigFile->stringify;
our %config;

#our %Config;
#our $ConfigFile = path("~/.hc.json")->stringify;
#if (path($ConfigFile)->is_file) {
#    %Config = JSON->new->utf8->decode(path($ConfigFile)->slurp)->%*;
#} else {
#    %Config = (
#	stats => {
#	    show => 1,
#	    sort_freq => 0,
#	},
#	pairs => {
#	    sort_keys => 1,
#	},
#    );
#    path($ConfigFile)->spew(JSON->new->utf8->pretty->encode(\%Config));
#}

# from perl cookbook..................................+
use Term::Cap;                                        #
my $OSPEED = 9600;                                    #
eval {                                                #
    require POSIX;                                    #
    my $termios = POSIX::Termios->new();              #
    $termios->getattr;                                #
    $OSPEED = $termios->getospeed;                    #
};                                                    #
my $terminal = Term::Cap->Tgetent({OSPEED=>$OSPEED}); #
our $clear = $terminal->Tputs('cl', 1, *STDERR);       #
#.....................................................+

use HC::UI;

use Headlines;
use ACA::Aristocrat;

1;
