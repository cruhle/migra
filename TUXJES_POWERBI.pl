#TUXJES_POWERBI.pl

#DESCRICAO DO REGISTO
#use constant	SERVIDOR	=>	0;
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

use File::Basename;

use lib 'lib';
require DateCalcFunctions;

my @registo;
my $work;
my $area;
my $start_time;
my $end_time;
my $data;
my $fp;
my $parm;
my $key;

my %jobs;

my $data_ficheiro=-1;

while(<DATA>) {

	chomp;
	$parm = $_;
	
	if(!-e $parm) {
		printf("---%s\n",$parm);
		next;
	}
	
	if($data_ficheiro == -1) {
		$data_ficheiro = basename($parm);
		$data_ficheiro =~ /(\d+)/;
		$data_ficheiro = $1;
	}
	
	open $fp,'<',$parm or die "ERROR $!\n";
	printf("%s\n",$parm);
	while(<$fp>) {
	
		next if(length $_ < 20);
		
		chomp;
		@registo = split(/\t/);
		next if(scalar @registo != 12);
		
		next if($registo[STEP_NAME] eq '-');
		next if(length($registo[START_TIME])!=9);
		next if(length($registo[END_TIME])!=9);
		
		$data = (split(/\s/,$registo[DATA_HORA]))[0];					
					
		$start_time = substr($registo[START_TIME],1);
		$end_time = substr($registo[END_TIME],1);	
				
	
		if($start_time gt $end_time) {
			$end_time = $data .' '. $end_time;
			$data = DateCalcFunctions::getYesterdayYYYYMMDD($data);
			$start_time = $data .' '. $start_time;
		} else {
			$start_time = $data .' '. $start_time;
			$end_time = $data .' '. $end_time;
		}
		
		$work = DateCalcFunctions::get_seconds_work_time($start_time, $end_time);
		
		$registo[DOMAIN] =~ s/BATCHPRD_//;	
		
		$key = $registo[JOB_NUMBER];
		
		if(exists($jobs{$key})) {
			$jobs{$key}{'runtime_seconds'} += $work;
		} else {
			$jobs{$key}{'job_name'} = $registo[JOB_NAME];
			$jobs{$key}{'runtime_seconds'} = $work;
			$jobs{$key}{'domain'} = $registo[DOMAIN];
			$jobs{$key}{'date_time'} = $registo[DATA_HORA];
			$jobs{$key}{'runtime_seconds'} = $work;
		}				
				
	}
	
	close $fp;
}	

my $ficheiro = '/tmp/pkis/LOG_4_POWERBI_'. $data_ficheiro .'.csv';
open my $fpo,'>', $ficheiro or die "ERROR $!\n";
#------------------------------------------------------
printf($fpo "%s\n",$0);
printf($fpo "DATE_TIME;DOMAIN;JOB_NUMBER;JOB_NAME;RUNTIME_SECONDS\n");

foreach(sort keys %jobs) {
	printf($fpo "%s;%s;%s;%s;%d\n",
		converteKEY($jobs{$_}{'date_time'}),
		$jobs{$_}{'domain'},
		$_,
		$jobs{$_}{'job_name'},
		$jobs{$_}{'runtime_seconds'}
	);
}
close $fpo;

printf("\n%s\n",$ficheiro);

#------------------------------------------------------
sub converteKEY {

	my $param = shift;
	$param = substr($param,0,4)."-".substr($param,4,2)."-".substr($param,6,2)." ".substr($param,9);
	
	return ($param);
}

__DATA__
/M_I_G_R_A/AT/jes_sys_log/co/2019/jessys.log.080419
/M_I_G_R_A/AT/jes_sys_log/rp/2019/jessys.log.080419
/M_I_G_R_A/AT/jes_sys_log/fo/2019/jessys.log.080419
/M_I_G_R_A/AT/jes_sys_log/pr/2019/jessys.log.080419
/M_I_G_R_A/AT/jes_sys_log/misc/2019/jessys.log.080419