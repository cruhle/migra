#TUXJES_YESTERDAY_POOL_BI.pl

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

use lib 'lib';
require DateCalcFunctions;

my ($d, $m, $y) = (localtime())[3..5];

$y+=1900;
$m++;

$y = sprintf("%4d%02d%02d",$y, $m, $d);

$m = DateCalcFunctions::getYesterdayYYYYMMDD($y);

my @registo;
my $work;
my $area;
my $start_time;
my $end_time;
my $data;
my $fp;
my $parm;
my $key;

my %data_job;
my %jobs;

my $ficheiro = '/tmp/pkis/RAW_LOG_FILE_'. $m .'_BI.csv';

while(<DATA>) {

	chomp;
	$parm = $_;
	
	if(!-e $parm) {
		printf("..%s..\n",$parm);
		next;
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
		
		next if($data ne $m);
		
		#passa hh:mm:ss para hh:00:00
		if(!exists($data_job{$registo[JOB_NUMBER]})) {
			$data_job{$registo[JOB_NUMBER]} = substr($registo[DATA_HORA],0,12) . '00:00';
		}
		$registo[DATA_HORA] = $data_job{$registo[JOB_NUMBER]};		
					
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
		
		$key = $registo[DATA_HORA] .';'. $registo[DOMAIN] .';'. $registo[JOB_NAME];
		
		$jobs{$key}{'runtime'} += $work;
		
		if(exists($jobs{$key}{'job_number'})) {
			if($jobs{$key}{'job_number'} ne $registo[JOB_NUMBER]) {
					$jobs{$key}{'qtd'} += 1;
					$jobs{$key}{'job_number'} = $registo[JOB_NUMBER];
			}
		} else {			
			$jobs{$key}{'job_number'} = $registo[JOB_NUMBER];
			$jobs{$key}{'qtd'} = 1;
		}				
				
	}
	
	close $fp;
}	

open my $fpo,'>', $ficheiro or die "ERROR $!\n";
printf($fpo "%s\n",$0);
printf($fpo "DATE_TIME;DOMAIN;JOB_NAME;QTD;RUNTIME_SECONDS\n");

foreach(sort keys %jobs) {
	printf($fpo "%s;%d;%d\n",
		converteKEY($_),
		$jobs{$_}{'qtd'},
		$jobs{$_}{'runtime'}
	);
}
close $fpo;

printf("\n%s\n",$ficheiro);
#------------------------------------------------------
sub converteKEY {

	my $param = shift;
	my @data = split(/;/,$param);
	$data[0] = substr($data[0],0,4)."-".substr($data[0],4,2)."-".substr($data[0],6,2)." ".substr($data[0],9);
	
	return ($data[0].';'.$data[1].';'.$data[2]);
}
#------------------------------------------------------
__DATA__
/M_I_G_R_A/AT/jes_sys_log/co/2019/jessys.log.101319
/M_I_G_R_A/AT/jes_sys_log/rp/2019/jessys.log.101319
/M_I_G_R_A/AT/jes_sys_log/fo/2019/jessys.log.101319
/M_I_G_R_A/AT/jes_sys_log/pr/2019/jessys.log.101319
/M_I_G_R_A/AT/jes_sys_log/misc/2019/jessys.log.101319