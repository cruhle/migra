#TUXJES_JOB_BY_STEP.pl

#/DEV/user/cobol_dv/load_csv

#OUPUT
#DATA-DOMAIN-JOBNAME-TIME_SECONDS
#SO JOBS COM work > 0

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
$filename = '/tmp/pkis/job_by_step_XX_'. $1 .'.csv';

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
	
	$key = $registo[JOB_NUMBER] . ';' . $registo[JOB_NAME] . ';' . $registo[STEP_NAME];
	
	$jobs{$key}{'work'} += $work;
	$jobs{$key}{'data'} = $registo[DATA_HORA];
	$jobs{$key}{'domain'} = $domain;
	$jobs{$key}{'job'} = $registo[JOB_NAME];
	$jobs{$key}{'step'} = $registo[STEP_NAME];
	$jobs{$key}{'ret_code'} = $registo[RETURN_CODE];
	
	#if($registo[RETURN_CODE] ne 'C0000') {
	#	$jobs{$key}{'ret_code'} = $registo[RETURN_CODE];
	#}
		
}
close $fp;

$filename =~ s/XX/$domain/g;

open $fp,'>',$filename;
printf($fp "%s\n",$0);

printf($fp "DATA;DOMAIN;JOB_NUMBER;JOB_NAME;STEP_NAME;TIME_SECONDS;RETURN_CODE\n");
$work=0;
foreach(sort keys %jobs) {

#	next if(exists($jobs{$_}{'ret_code'}));
	next if($jobs{$_}{'work'}==0);

	printf($fp "%s;%s;%s;%d;%s\n",
		$jobs{$_}{'data'},
		$jobs{$_}{'domain'},
		$_,
		$jobs{$_}{'work'},
		$jobs{$_}{'ret_code'}
	);
	$work+=1;
}
close $fp;

printf("[%s] [%d]\n",$filename, $work);


