#TUXJES_TAIL.pl

#/DEV/user/cobol_dv/load_csv

#OUPUT
#DATA-JOBNAME-DOMAIN-JOBS-STEPS-TIME_SECONDS
#NR DE JOBS POR DIA COM A QTD DE STEPS E DURACAO

use strict;
use warnings;
use integer;
use File::Basename;

use lib 'lib';
require DateCalcFunctions;

use constant	DEBUG		=>	0;

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

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	printf("File [%s] not FOUND.\n",$parm);
	exit;
}

my $filename = basename($parm);
$filename =~ /(\d+)/;
$filename = '/tmp/pkis/jobs_XX_'. $1 .'.csv';

my @registo;
my ($start_time, $end_time, $key, $work, $domain) =(0, 0, '', 0, '');
my %jobs;


open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	chomp;	
	
	@registo = split(/\t/);		
	
	next if(scalar @registo != 12);
	next if($registo[STEP_NAME] eq '-');
	next if(length($registo[START_TIME])!=9);
	next if(length($registo[END_TIME])!=9);
	
	$start_time = DateCalcFunctions::time_2_seconds(substr($registo[START_TIME],1));
	$end_time 	= DateCalcFunctions::time_2_seconds(substr($registo[END_TIME],1));
	$work 		= DateCalcFunctions::valida_tempos($start_time, $end_time);
	
	$registo[DATA_HORA] = (split(/\s/,$registo[DATA_HORA]))[0];	
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	$domain = $registo[DOMAIN];
	$key = $registo[DATA_HORA] .';'. $registo[JOB_NAME] .';'. $registo[DOMAIN];
	
	if(exists($jobs{$key})) {
		$jobs{$key}{'work'} += $work;
		$jobs{$key}{'steps'} += 1;
		if($registo[STEP_NAME] eq 'START') {
			$jobs{$key}{'job'} += 1;
		}
	} else {
		$jobs{$key} = {
			'work' => $work,
			'steps' => 1,
			'job' => 1
		};
	}
	
		
}
close $fp;

$filename =~ s/XX/$domain/g;

open $fp,'>',$filename;
printf($fp "%s\n",$0);

printf($fp "DATA;JOBNAME;DOMAIN;JOBS;STEPS;TIME_SECONDS\n");
$work=0;
foreach(sort keys %jobs) {
	printf($fp "%s;%d;%d;%d\n",$_,$jobs{$_}{'job'},$jobs{$_}{'steps'} ,$jobs{$_}{'work'});
#	printf("%d\t%.2f\n",$jobs{$_}{'work'},log($jobs{$_}{'work'})/log(10)) if($jobs{$_}{'work'}>0);
	$work+=1;
}
close $fp;

printf("[%s] [%d]\n",$filename, $work);


