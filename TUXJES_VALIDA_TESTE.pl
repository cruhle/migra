#TUXJES_VALIDA_TESTE.pl

#REGISTO DO FICHEIRO DE LOG
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;	#	-	
use constant	JOB_STATUS	=>	6;
use constant	RETURN_CODE	=>	7;

use constant	START_TIME	=>	6;
use constant	END_TIME	=>	7;

use strict;
use warnings;
use integer;

my @registo;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

my $fp;

open $fp,'<',$parm or die "ERROR $!\n";

printf("Reading %s ....\n\n",$parm);

my $quebra='';

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	
	@registo = split(/\t/);					
	
	next if($registo[JOB_NUMBER] !~ /01404561|01406402/);	
	
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	
	#separa se +k1 job com linhas intervaladas
	#if($quebra eq '') {
	#	$quebra = $registo[JOB_NUMBER];
	#}
	#
	#if($quebra ne $registo[JOB_NUMBER]) {
	#	printf("\n");
	#	$quebra = $registo[JOB_NUMBER];
	#}
	
	printf("%s %s %s %s ", $registo[DATA_HORA], $registo[DOMAIN], $registo[JOB_NUMBER], $registo[JOB_NAME]); 
	
	if($registo[STEP_NAME] eq '-') {
		printf("%s\n", $registo[JOB_STATUS]); 
	} else {
		$registo[START_TIME] =~ s/S//;
		$registo[END_TIME] =~ s/E//;
		printf("%-15s %s %s \n", $registo[STEP_NAME], $registo[START_TIME], $registo[END_TIME]); 
	}		
			
}

close $fp;


