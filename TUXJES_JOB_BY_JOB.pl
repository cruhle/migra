#TUXJES_JOB_BY_JOB.pl

#/DEV/user/cobol_dv/load_csv

#OUPUT
#DATA-DOMAIN-JOBNAME-TIME_SECONDS
#SO JOBS QUE TERMINARAM COM C000 EM TODOS OS STEPS

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
$filename = '/tmp/pkis/job_by_job_XX_'. $1 .'.csv';

my @registo;
my ($start_time, $end_time, $key, $work, $domain, $linhas) =(0, 0, '', 0, '',0);
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
	
	$jobs{$registo[JOB_NUMBER]}{'work'} += $work;
	$jobs{$registo[JOB_NUMBER]}{'data'} = $registo[DATA_HORA];
	$jobs{$registo[JOB_NUMBER]}{'domain'} = $domain;
	$jobs{$registo[JOB_NUMBER]}{'job'} = $registo[JOB_NAME];
	
	if($registo[RETURN_CODE] ne 'C0000') {
		$jobs{$registo[JOB_NUMBER]}{'ret_code'} = $registo[RETURN_CODE];
	}
		
}
close $fp;

$filename =~ s/XX/$domain/g;

my %max_job;

open $fp,'>',$filename;
printf($fp "%s\n",$0);

printf($fp "DATA;DOMAIN;JOB_NUMBER;JOB_NAME;TIME_SECONDS\n");

$linhas=0;
foreach(sort keys %jobs) {

	next if(exists($jobs{$_}{'ret_code'}));

	printf($fp "%s;%s;%s;%s;%d\n",
		$jobs{$_}{'data'},
		$jobs{$_}{'domain'},
		$_,
		$jobs{$_}{'job'},
		$jobs{$_}{'work'}
	);
	$linhas+=1;
	
	$key = $jobs{$_}{'job'};
	$work = $jobs{$_}{'work'};
	
	if(exists($max_job{$key})) {
		if($work > $max_job{$key}{'max'}) {
			$max_job{$key}{'max'}=$work;
			$max_job{$key}{'max_job'}=$_;
		}
		if($work < $max_job{$key}{'min'}) {
			$max_job{$key}{'min'}=$work;
			$max_job{$key}{'min_job'}=$_;
		}
	} else {
		$max_job{$key}{'min'}=$work;
		$max_job{$key}{'max'}=$work;
		$max_job{$key}{'max_job'}=$_;
		$max_job{$key}{'min_job'}=$_;
		$max_job{$key}{'domain'}=$jobs{$_}{'domain'};
	}
	
}
close $fp;

printf("[%s] [%d]\n",$filename, $linhas);

printf("DOMAIN;JOB_NAME;JOB_NBR_MIN;TIME_MIN;JOB_NBR_MAX;TIME_MAX\n");
foreach(sort keys %max_job) {
	printf("%s;%s;%s;%d;%s;%d\n",
		$max_job{$_}{'domain'}, 
		$_, 
		$max_job{$_}{'min_job'}, 
		$max_job{$_}{'min'}, 
		$max_job{$_}{'max_job'}, 
		$max_job{$_}{'max'}
	);
}


