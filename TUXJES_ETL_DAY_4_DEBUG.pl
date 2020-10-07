#TUXJES_ETL_DAY_4_DEBUG.pl

use strict;
use warnings;
use integer;

use lib 'lib';
require DateCalcFunctions;

#DESCRICAO DO REGISTO
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
use constant	START_TIME	=>	6;
use constant	END_TIME	=>	7;
use constant	RETURN_CODE	=>	11;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	printf("File [%s] not FOUND.\n",$parm);
	exit;
}

my $data_para_filtrar = '20190727';

my ($start_time, $end_time, $work) = ('', '', 0);
my @registo;

printf("[%s]\n",$parm);

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length($_)) < 20;
	next if(!/$data_para_filtrar/);
	
	chomp;		
	@registo = split(/\t/);		
	
	next if($registo[STEP_NAME] eq '-');
	
	$start_time = DateCalcFunctions::time_2_seconds(substr($registo[START_TIME],1));
	$end_time = DateCalcFunctions::time_2_seconds(substr($registo[END_TIME],1));		
	$work = DateCalcFunctions::valida_tempos($start_time, $end_time);
	
	printf("%s;%s;%s;%s;%s;%s;%d;%s\n",
		$registo[DATA_HORA],
		$registo[JOB_NUMBER],
		$registo[JOB_NAME],
		$registo[STEP_NAME],
		substr($registo[START_TIME],1),
		substr($registo[END_TIME],1),
		$work,		
		$registo[RETURN_CODE]
	);
	
		
}
close $fp;

