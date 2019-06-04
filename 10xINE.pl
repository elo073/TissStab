#!/usr/bin/perl

use strict;
use warnings;
use autodie;
use Getopt::Long;


my %barcodes;        # identifies our target barcodes

my @ARGV_COPY  = @ARGV;
my $n_args = @ARGV;

my $help  =  0;
my $progname = 'samdemux.pl';
my $barcodefile = "";


sub help {
   print <<EOH;
Usage:
   $progname [options]
Options:
--help                  this
--barcodefile=<FNAME>       file with barcodes
EOH
}


if
(! GetOptions
   (  "help"            =>   \$help
   ,  "barcodefile=s"   =>   \$barcodefile
   )
)
   {  print STDERR "option processing failed\n";
      help();
      exit(1);
   }

if (!$n_args || $help) {
   help();
   exit(0);
}

open(BARCODES, '<', $barcodefile) || die "Cannot open barcode file $barcodefile";

while (<BARCODES>) {
  chomp;
  my $bc = $_;
  $barcodes{$bc} = { E255 => 0, N255 => 0, I255 => 0,  Eother => 0, Nother => 0, Iother => 0 } ;
}
print STDERR "Done reading barcodes\n";
close BARCODES;

my $N_READ = 0;
my $N_miss = 0;

while (<>) {

  next if /^@/;
  chomp;
  my @F = split "\t", $_;
  my $q = $F[4];
  my $tag = $q eq '255' ? '255' : 'other';

  my $bc = "NA";

  $N_READ++;
  if (m{\tCB:Z:(\S+)\b}) {
    $bc = $1;
    next unless defined($barcodes{$bc});
  }
  if (! /\bRE:A:([INE])\b/) {
    $N_miss++;
    next;
  }
  $barcodes{$bc}{$1 . $tag}++;

  if ($N_READ % 100000 == 0) {            # 100 dots per line, each dot 100,000 reads.
    print STDERR '.';
  }
  if ($N_READ % 10000000 == 0) {          # 10M reads per line.
    printf STDERR " %3d\n", $N_READ / 10000000;
  }
}
print STDERR "\n($N_miss lines failed to match RE:A:[INE])\n";


local $" = "\t";
my @order = qw(E255 N255 I255 Eother Nother Iother);
print "\t@order\n";

for my $bc (sort keys %barcodes) {
  my @counts = map { $barcodes{$bc}{$_} } @order;
  print "$bc\t@counts\n";
}



