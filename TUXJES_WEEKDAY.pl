#TUXJES_WEEKDAY.pl

#copia os registo do dia anterior
#weekdays
#1	seg
#2	ter
#3	qua
#4	qui
#5	sex
#6	sab
#7	dom
#cria ficheiro diary_DOMAIN_data.csv
#data = dia de ontem

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

use constant	DOMINGO		=>	7;

use strict;
use warnings;

use File::Basename;

use lib 'lib';
require DateCalcFunctions;

my $current_date = DateCalcFunctions::getCurrentDate();
my $filter_date = DateCalcFunctions::getYesterdayYYYY_MM_DD($current_date);
my $z = $current_date;
$z =~ /^(\d{4})-(\d{2})-(\d{2})$/;
#ano-4 mes dia
my $week_day = DateCalcFunctions::getWeekday($1,$2,$3);

#printf("(%s)\t(%s)\t(%d)\n",
#	$current_date,
#	$filter_date,
#	$week_day);

##my $parm;
##
##if($week_day == DOMINGO) {
##	#$parm = `ls \$JESROOT/jessyslog/jessys.log.* | tail -n 2 | head -n 1`;
##	$parm = `ls -d rp/2019/* | tail -n 2 | head -n 1`;
##} else {
##	#$parm = `ls \$JESROOT/jessyslog/jessys.log.* | tail -n 1`;
##	$parm = `ls -d rp/2019/* | tail -n 1`;
##}
##
##chomp $parm;

#old version, not in use any more!
my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

printf(".. %s ..\n",$parm);

my @registo;
my ($start_time, $end_time, $work, $domain, $key) = ('', '', 0, '', '');

my %step_date;
my %step_counter;
my %jobs;

my $log_date;
my $log_time;
my $step_key;
my $tmp;

my $linhas = 0;

my $filename = basename($parm);
#$filename =~ /(\d+)/;
$filename = '/tmp/pkis/DIARY_XX_'. $filter_date .'.csv';

open my $fpo,'>', $filename or die "ERROR $!\n";
printf($fpo "%s\n",$0);
printf($fpo "SERVER;DATE_TIME;JOB_NUMBER;DOMAIN;JOB_NAME;STEP_NAME;STEP_NUMBER;");
printf($fpo "STEP_START_TIME;STEP_END_TIME;STEP_RUNTIME_SECONDS;RETURN_CODE\n");
open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);
	
	next if($registo[DATA_HORA] !~ /^$filter_date/);
	next if(scalar @registo != 12);
	next if($registo[STEP_NAME] eq '-');
	next if(length($registo[START_TIME])!=9);
	next if(length($registo[END_TIME])!=9);
				
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	$domain = $registo[DOMAIN];

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
	

	printf($fpo "%s;", $registo[SERVIDOR]);
	printf($fpo "%s;%s;%s;", $registo[DATA_HORA],$key,$domain);
	printf($fpo "%s;%s;%d;", $jobs{$key}{'job_name'},$jobs{$key}{'step_name'},$jobs{$key}{'step_number'});	
	printf($fpo "%s;%s;", $jobs{$key}{'start_time'}, $jobs{$key}{'end_time'});
	
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

$fp = $filename;
$filename =~ s/XX/$domain/g;

rename($fp, $filename);
printf("%s %d\n",$filename, $linhas);
	
#D:\M_I_G_R_A\AT\jes_sys_log>ls rp\2019\ | tail -n 1
#jessys.log.111719
#
#D:\M_I_G_R_A\AT\jes_sys_log>ls rp\2019\ | tail -n 2
#jessys.log.111019
#jessys.log.111719
#
#D:\M_I_G_R_A\AT\jes_sys_log>ls rp\2019\ | tail -n 2 | head -n 1
#jessys.log.111019	
