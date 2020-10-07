#TUXJES_CLEAN_RAW.pl

#/DEV/user/cobol_dv/load_csv

use strict;
use warnings;
use File::Basename;

use Time::Piece ();
use Time::Seconds;

use lib 'lib';
require DateCalcFunctions;

#DESCRICAO DO REGISTO
use constant	SERVIDOR	=>	0;
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
use constant	START_TIME	=>	6;
use constant	END_TIME	=>	7;
use constant	RETURN_CODE	=>	11;

#my $parm = `ls -t1 \$JESROOT/jessyslog/jessys.log.* | head -2 | tail -1`;

my ($parm) =  @ARGV; 

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my $filename = basename($parm);
#$filename =~ /(\d+)/;
$filename = '/tmp/pkis/jobs_steps_XX_'. '.csv';

my @registo;
my %contador;
my ($key, $domain) = ('','');
my ($start_time, $end_time, $work, $lnhs)=(0, 0, 0, 0);

#jobs start and end time
my ($data_log, $job_start_time, $job_end_time, $tmp) = ('', '', '', '');
#jobs start and end time

open my $fp,'<',$parm or die "ERROR $!\n";

open my $fpout,'>',$filename or die "ERROR $$!\n";

printf($fpout "%s\n",$0);
#printf($fpout "DATE_TIME;DOMAIN;JOB_NUMBER;JOB_NAME;STEP_NAME;STEP_NUMBER;STEP_START;STEP_END;TIME_SECONDS;RETURN_CODE\n");
printf($fpout "DATE_TIME;DOMAIN;JOB_NUMBER;JOB_NAME;STEP_NAME;STEP_NUMBER;TIME_SECONDS;RETURN_CODE\n");

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);			
		
	next if(scalar @registo != 12);
	next if(length($registo[STEP_NAME]) eq '-');
	next if(length($registo[START_TIME])!=9);
	next if(length($registo[END_TIME])!=9);
			
	$start_time = DateCalcFunctions::time_2_seconds(substr($registo[START_TIME],1));
	$end_time = DateCalcFunctions::time_2_seconds(substr($registo[END_TIME],1));		
	$work = DateCalcFunctions::valida_tempos($start_time, $end_time);	
	$registo[DOMAIN] =~ s/BATCHPRD_//;
	$domain = $registo[DOMAIN];
	
	$key = $registo[JOB_NUMBER] .';'. $registo[JOB_NAME];
		
	$contador{$key}+=1;
	
#jobs start and end time
	$data_log = (split(/\s/,$registo[DATA_HORA]))[0];
	$job_start_time = substr($registo[START_TIME],1);
	$job_end_time = substr($registo[END_TIME],1);			
	$job_end_time = $data_log .' '. $job_end_time;
	if($start_time > $end_time) {
		$tmp = Time::Piece->strptime( $data_log, '%Y%m%d');
		$tmp -= ONE_DAY;
		$data_log = $tmp->strftime('%Y%m%d');		
	}	
	$job_start_time = $data_log .' '. $job_start_time;
#jobs start and end time	

	#printf($fpout "%s;%s;%s;%s;%s;%d;%s;%s;%d;%s\n",
	printf($fpout "%s;%s;%s;%s;%s;%d;%d;%s\n",
		$registo[DATA_HORA],
		$registo[DOMAIN],
		$registo[JOB_NUMBER],
		$registo[JOB_NAME], 
		$registo[STEP_NAME],
		$contador{$key},
		#$job_start_time,
		#$job_end_time,		
		$work,
		$registo[RETURN_CODE]
	); # if($start_time > $end_time);
	
	$lnhs++;
}
close $fp;
close $fpout;

$fp = $filename;
$fp =~ s/XX/$domain/g;

rename($filename, $fp);

printf("[%s] [%d]\n",$fp, $lnhs);




