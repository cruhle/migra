#TUXJES_JOBNR.pl

#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog
#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT_BCK/01318783.bak
#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT_BCK/01402145.bak

#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT
#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT/.bak

use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;

use strict;
use warnings;
use integer;

my $parm = shift || die "Usage: $0 FILE\n";

my %jobs;

my $jobnr;
my $jobname;
my $key;

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	#TESTES
	#unless(/.+[TTTMBCSI|TTATTTRF]\sLATMB.+/) {
	#	next;
	#}

	#PRODUCAO
#	unless(/.+[PTTMBCSI|PTATTTRF]\sLATMB.+/) {
	unless(/.+(PTTMBCSI|PTATTTRF)\s[A-Z0-9]+.+/) {
		next;
	}
		
	$jobnr = (split(/\t/))[JOB_NUMBER];
	$jobname = (split(/\t/))[JOB_NAME];
	$key = $jobnr .';' . $jobname;
	
	$jobs{$key} +=1;
		
}
close $fp;

foreach(sort keys %jobs) {
	printf("%s\t%d\n",$_, $jobs{$_});
}


