#TUXJES_JOB_STRIP.pl

use strict;
use warnings;
use File::Basename;

use Time::Piece ();
use Time::Seconds;

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

my ($parm) =  @ARGV; 

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my (@registo, %tabela, %jobs, $key, $filename, $domain) = ((), (), (), '', '', '');
my ($start_time, $end_time, $work, $tmp, $data_log, $counter) = (0, 0, 0, '', '', 0);


#filename name to write the output
$filename = basename($parm);
$filename =~ /(\d+)/;
$filename = '/tmp/pkis/jobs_strip_XX_'. $1 .'.csv';

open my $fp,'<',$parm or die "ERROR $!\n";
open my $fpo,'>',$filename or die "ERROR $!\n";
printf($fpo "%s\n",$0);

printf($fpo "JOB_NUMBER;JOB_NAME;DOMAIN;FILE_LOG_DATA;STEP_NAME;STEP_NUMBER;STEP_START_TIME;STEP_END_TIME;STEP_TIME_SECONDS;RETURN_CODE\n");
while(<$fp>) {

	next if(length($_)<61);

	chomp;
	@registo 			= split(/\t/);
	$key = @registo;
	next if($key < 6);
	
	next if($registo[START_TIME] eq 'AUTOPURGED');
	
	$registo[DOMAIN] 	=~ s/BATCHPRD_//;
	$domain 			= $registo[DOMAIN];
	$key 				= $registo[JOB_NUMBER];
	
	$data_log = (split(/\s/,$registo[DATA_HORA]))[0];
	
	# job step number accumulator
	$jobs{$key}+=1;	

	$tabela{$key}{'job_name'} 		= $registo[JOB_NAME];
	$tabela{$key}{'domain'} 		= $registo[DOMAIN];
	$tabela{$key}{'file_log_data'} 	= $registo[DATA_HORA];
	$tabela{$key}{'step_number'} 	= $jobs{$key};
	$tabela{$key}{'return_code'}	= '';
	
	$start_time = 0;
	$end_time = 0;
	$work = '';
		
	if($registo[STEP_NAME] eq '-') {
		$tabela{$key}{'step_name'} = $registo[START_TIME];
		if($registo[START_TIME] eq 'ENDED') {			
			$tabela{$key}{'return_code'} = $registo[END_TIME];
		}
	}
	
	if($registo[STEP_NAME] ne '-') {
		$tabela{$key}{'step_name'} = $registo[STEP_NAME];
		$tabela{$key}{'return_code'} = $registo[RETURN_CODE];		
		if(length($registo[START_TIME]) == 9 and length($registo[END_TIME]) == 9) {
			$registo[START_TIME] = substr($registo[START_TIME],1);
			$registo[END_TIME] = substr($registo[END_TIME],1);
			$start_time = DateCalcFunctions::time_2_seconds($registo[START_TIME]);
			$end_time = DateCalcFunctions::time_2_seconds($registo[END_TIME]);
			$work = DateCalcFunctions::valida_tempos($start_time,$end_time);
		} 						
	}

	$counter++;
	printf($fpo "%s;%s;%s;%s;%s;%d;",
		   $key,
		   $registo[JOB_NAME],
		   $registo[DOMAIN],
		   $registo[DATA_HORA],
		   $tabela{$key}{'step_name'},
		   $tabela{$key}{'step_number'}
	);
	
	if($start_time > 0) {
		if($start_time > $end_time) {
			$tmp = Time::Piece->strptime( $data_log, '%Y%m%d');
			$tmp -= ONE_DAY;
			$tmp = $tmp->strftime('%Y%m%d');		
			$tmp = $tmp .' '. $registo[START_TIME];
		} else { $tmp = $data_log .' '. $registo[START_TIME]; }
	} else { $tmp = ''; }
	printf($fpo "%s;", $tmp);
	
	if($end_time > 0) {
		$tmp = $data_log .' '. $registo[END_TIME];
	} else { $tmp = ''; }
	printf($fpo "%s;", $tmp);

	if($start_time > 0 and $end_time > 0) {
		$tmp = $work;
	} else { $tmp = ''; }
	printf($fpo "%s;", $tmp);
	
	printf($fpo "%s\n", $tabela{$key}{'return_code'});
	
}
close $fp;
close $fpo;

$fp = $filename;
$filename =~ s/XX/$domain/g;
rename($fp, $filename);
printf("Ficheiro [%s] [%d] criado.\n",$filename, $counter);


