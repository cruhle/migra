#TUXJES_ETL_MAX.pl

#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog
#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT_BCK/01318783.bak

#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT

use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;

use strict;
use warnings;

my @ins;
my $maxJBNM=0;
my $maxSTPNM=0;

my $code;

my ($parm) = @ARGV;

if(!-e $parm) {
	printf("FILE [%s] NOT FOUND.\n",$parm);
	exit ;
}

open my $fp,'<',$parm or die "ERROR $!\n";
my $linhas=0;
while(<$fp>) {
	$linhas++;
	next if(length $_ < 20);
	
	chomp;
	@ins = split(/\t/);
		
	next if(scalar @ins != 12);
	next if($ins[STEP_NAME] eq '-');
	
	if(length($ins[JOB_NAME])> $maxJBNM) {
		$maxJBNM = length($ins[JOB_NAME]);
	}
	
	if(length($ins[STEP_NAME])> $maxSTPNM) {
		$maxSTPNM = length($ins[STEP_NAME]);
	}	
						
}
close $fp;
printf("%s [%6d] ",$parm,$linhas);
printf("JOB: %2d\t",$maxJBNM);
printf("STEP: %2d\n",$maxSTPNM);


