#TUXJES_ETL_CTPX.pl

use strict;
use warnings;

use lib 'lib';
require DateCalcFunctions;

#DESCRICAO DO REGISTO
use constant	DATA			=>	2;
use constant	JOB_NUMBER		=>	3;
use constant	STEP_NAME		=>	5;
use constant	START_TIME		=>	6;
use constant	END_TIME		=>	7;

my ($parm) =  @ARGV; 

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my @registo;
my $found;
my ($start_time, $end_time, $work) = (0, 0, 0);

#printf("DATA;JOB_NUMBER;STEP_NAME;START_TIME;END_TIME;TIME_SECONDS\n");
open my $fp,'<',$parm or die "ERROR $!\n";
while(<$fp>) {

	chomp;
	$found = 0;
	
	if(/\tPTPTCTP1\tCTP1\t/) {
		$found = 1;
	}
	if(/\tPTPTCTP3\tCTP3\t/) {
		$found = 1;
	}
	
	if($found == 1) {
		@registo = split(/\t/);
		$start_time = DateCalcFunctions::time_2_seconds(substr($registo[START_TIME],1));
		$end_time = DateCalcFunctions::time_2_seconds(substr($registo[END_TIME],1));
		$work = DateCalcFunctions::valida_tempos($start_time, $end_time);
		printf("%s;%s;%s;%s;%s;%d\n",
			$registo[DATA],
			$registo[JOB_NUMBER],
			$registo[STEP_NAME],
			substr($registo[START_TIME],1),
			substr($registo[END_TIME],1),
			$work
		);
	}
	
}
close $fp;

