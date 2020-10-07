#TUXJES_CRON_TAB.pl

#REGISTO DO FICHEIRO DE LOG
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
use constant	START_TIME	=>	6;
use constant	END_TIME	=>	7;
use constant	RETURN_CODE	=>	11;

use strict;
use warnings;
use integer;

use lib 'lib';
require DateCalcFunctions;

my @registo;
my $start_time=0;
my $work;

my $parm;
my $fp;
my %jobs;
my %ended_jobs;

my $end_time = DateCalcFunctions::time_2_seconds(DateCalcFunctions::getCurrenttime());

while(<DATA>) {

	chomp;
	$parm = $_;
	
	open $fp,'<',$parm or die "ERROR $!\n";
	printf("Reading %s ....\n",$parm);
	
	while(<$fp>) {
	
		next if(length $_ < 20);
		
		chomp;
		@registo = split(/\t/);					
		
		if($registo[START_TIME] =~ /^ENDED$/) {
			$ended_jobs{$registo[JOB_NUMBER]}=1;
		}
		
		next if(scalar @registo != 12);
		next if($registo[STEP_NAME] eq '-');			
		next if(length($registo[START_TIME])!=9);
		next if(length($registo[END_TIME])!=9);
		
		next if($registo[STEP_NAME] !~ /(START|END_JOB)/);							
		
		$start_time = DateCalcFunctions::time_2_seconds(substr($registo[START_TIME],1));		
		
		$registo[DOMAIN] =~ s/BATCHPRD_//;	
		
		if(exists($jobs{$registo[JOB_NUMBER]})) {
			delete $jobs{$registo[JOB_NUMBER]};
		} else {
			$jobs{$registo[JOB_NUMBER]}{'job_name'} = $registo[JOB_NAME];
			$jobs{$registo[JOB_NUMBER]}{'start_seconds'} = $start_time;
			$jobs{$registo[JOB_NUMBER]}{'domain'} = $registo[DOMAIN];
			#$jobs{$registo[JOB_NUMBER]}{'start_time'} = substr($registo[START_TIME],1);
			$jobs{$registo[JOB_NUMBER]}{'start_time'} = $registo[DATA_HORA];
			$jobs{$registo[JOB_NUMBER]}{'step_name'} = $registo[STEP_NAME];
		}
				
	}
	
	close $fp;

}	


my $filename = '/tmp/pkis/logs_start_end_job.csv';
open my $fpo,'>',$filename or die "ERROR $!\n";
printf($fpo "%s\n",$0);
printf($fpo "DATE_TIME;JOB_NUMBER;JOB_NAME;DOMAIN;START_TME;RUNTIME;RUNTIME_SECONDS\n");

foreach(sort keys %jobs) {

	next if($jobs{$_}{'step_name'} =~ /^END_JOB/);
	
	next if(exists($ended_jobs{$_}));
	
	$work = DateCalcFunctions::valida_tempos($jobs{$_}{'start_seconds'}, $end_time);
	
	printf($fpo "%s;%s;%s;%s;%s;%s;%d\n",
			DateCalcFunctions::getLocaltime(),
			$_,
			$jobs{$_}{'job_name'},
			$jobs{$_}{'domain'},
			$jobs{$_}{'start_time'},
			DateCalcFunctions::seconds_2_time($work),
			$work
		);
	
}

close $fpo;
printf("Ficheiro [%s] criado.\n",$filename);

__DATA__
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.091519
/M_I_G_R_A/AT/jes_sys_log/CO/jessys.log.091519
/M_I_G_R_A/AT/jes_sys_log/FO/jessys.log.091519