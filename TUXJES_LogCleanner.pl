#TUXJES_LogCleanner.pl

#use File::Basename;

#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT

use constant	DATA_HORA	=>	2;
use strict;
use warnings;
use integer;

my $parm = shift || die "Usage: $0 FILE\n";

#my $filename = basename($parm);
my @ins;
my @dh;
my $ano=0;

my %contador_de_anos;

open my $fp,'<',$parm or die "ERROR $!\n";
open my $fpo,'>','jessys_2019.log' or die "ERROR $!\n";
printf($fpo "%s\n",$0);

while(<$fp>) {
	#chomp;
	@ins = split(/\t/);
	
	$ano = substr((split(/\s/,$ins[DATA_HORA]))[0],0,4);
	if($ano==2019) {
		print $fpo $_;
	}
	
	#if($ano != 2019) { next; } 
	#foreach(@ins) {
	#	print;
	#	print "\n";
	#}
	
	##$contador_de_anos{$ano}+=1;
	
	
	#@dh = split(/\s/,$ins[DATA_HORA]);
	#print $dh[0],"\t\t",$dh[1],"\t",$ano;
	#print "\n";
}
close $fp;
close $fpo;

foreach(sort keys %contador_de_anos) {
	printf("%d\t%d\n",$_, $contador_de_anos{$_});
}

