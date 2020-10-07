#perl TUXJES_LOG_ALL_IN_ONE.pl rp\jessys.log.031019

#TUXJES_LOG_ALL_IN_ONE.pl

#e mudar o EOL para unix
#e upload para a DB

#DESCRICAO DO REGISTO
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

use File::Basename;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my @registo;
my ($start_time, $end_time, $work, $key) = ('', '', 0, '');

my %step_date;
my %step_counter;
my %jobs;

my $log_date;
my $log_time;
my $step_key;
my $tmp;

my $linhas = 0;

my $filename = basename($parm);
$filename =~ /(\d+)/;
$filename = '/tmp/pkis/LOG_'. $1 .'.csv';

my $fpo;
if(!-e $filename) {
	open $fpo,'>', $filename or die "ERROR $!\n";
	printf($fpo "%s\n",$0);
	printf($fpo "DATE_TIME;JOB_NUMBER;DOMAIN;JOB_NAME;STEP_NAME;STEP_NUMBER;");
	printf($fpo "STEP_START_TIME;STEP_END_TIME;STEP_RUNTIME_SECONDS;RETURN_CODE\n");
}else {
	open $fpo,'>>', $filename or die "ERROR $!\n";
}

open my $fp,'<',$parm or die "ERROR $!\n";
while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);
	
	#next if($registo[JOB_NUMBER] ne '01316112');
	
	next if(scalar @registo != 12);
	next if($registo[STEP_NAME] eq '-');
	next if(length($registo[START_TIME])!=9);
	next if(length($registo[END_TIME])!=9);
				
	$registo[DOMAIN] =~ s/BATCHPRD_//;	

	$key = $registo[JOB_NUMBER];
	$step_counter{$key} += 1;
	
	($log_date, $log_time) = (split(/\s/,$registo[DATA_HORA]));
	
	$jobs{$key}{'job_name'} = $registo[JOB_NAME];
	$jobs{$key}{'step_number'} = $step_counter{$key};
	$jobs{$key}{'step_name'} = $registo[STEP_NAME];
	$jobs{$key}{'start_time'} = substr($registo[START_TIME],1);
	$jobs{$key}{'end_time'} = substr($registo[END_TIME],1);
		
	$step_key = $key . sprintf(" %03d",$step_counter{$key});
	
	$step_date{$step_key} = $log_date;				
	
	if($step_counter{$key} == 1) {		
	
		if($jobs{$key}{'start_time'} gt $jobs{$key}{'end_time'}) {
			$jobs{$key}{'start_time'} = DateCalcFunctions::getYesterdayYYYYMMDD($log_date)
				. ' ' 
				. $jobs{$key}{'start_time'};	
		} else {
			$jobs{$key}{'start_time'} = $log_date . ' ' . $jobs{$key}{'start_time'};
		}
	
		$jobs{$key}{'end_time'} = $log_date . ' ' . $jobs{$key}{'end_time'};
	}
	
	if($step_counter{$key} > 1) {
		$tmp = $key . sprintf(" %03d", ($step_counter{$key} - 1));	
		$jobs{$key}{'start_time'} = $step_date{$tmp} . ' ' . $jobs{$key}{'start_time'};
		$jobs{$key}{'end_time'} = $log_date . ' ' . $jobs{$key}{'end_time'};
	}
	
	#ORACLE
	printf($fpo "%s;%s;%s;", $registo[DATA_HORA],$key,$registo[DOMAIN]);
	#POWER-BI
	#printf($fpo "%s;%s;%s;", DateCalcFunctions::converteData2PowerBI($registo[DATA_HORA]),$key,$registo[DOMAIN]);
	printf($fpo "%s;%s;%d;", $jobs{$key}{'job_name'},$jobs{$key}{'step_name'},$jobs{$key}{'step_number'});
	
	#ORACLE
	printf($fpo "%s;%s;", $jobs{$key}{'start_time'}, $jobs{$key}{'end_time'});
	#POWER-BI
	#printf($fpo "%s;%s;"
	#	, DateCalcFunctions::converteData2PowerBI($jobs{$key}{'start_time'})
	#	, DateCalcFunctions::converteData2PowerBI($jobs{$key}{'end_time'}));
	
	if($jobs{$key}{'start_time'} eq $jobs{$key}{'end_time'}) {
		printf($fpo "%d",0);
	} else {
		printf($fpo "%d", DateCalcFunctions::get_seconds_work_time(
			$jobs{$key}{'start_time'},
			$jobs{$key}{'end_time'}
			));
	}
	
	printf($fpo ";%s\n",$registo[RETURN_CODE]);
	
	$linhas++;
}
close $fp;
close $fpo;

printf("%s %d\n",$filename, $linhas);








