#TUXJES_DAILY_HOURLY.pl

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
my $current_hour = DateCalcFunctions::getCurrentHourHH();

my $filter_date;
my $name_2_file;

if($current_hour == 0) {
	$current_date = DateCalcFunctions::getYesterdayYYYY_MM_DD($current_date);
	$current_date =~ s/-//g;
	$filter_date = $current_date .' 23:';
	$name_2_file = $current_date .'_23:';
} else {
	$current_hour-=1;
	$current_date =~ s/-//g;
	$filter_date = $current_date .' '. sprintf("%02d:", $current_hour);
	$name_2_file = $current_date .'_'. sprintf("%02d", $current_hour);
}

my $z = $current_date;
#$z =~ /^(\d{4})-(\d{2})-(\d{2})$/;
$z =~ /^(\d{4})(\d{2})(\d{2})$/;
#ano-4 mes dia
my $week_day = DateCalcFunctions::getWeekday($1,$2,$3);

#printf("(%s)\t(%s)\t(%d)\n",
#	$current_date,
#	$filter_date,
#	$week_day);

my $parm;

if($week_day == DOMINGO) {
	#$parm = `ls \$JESROOT/jessyslog/jessys.log.* | tail -n 2 | head -n 1`;
	$parm = `ls -d rp/2019/* | tail -n 2 | head -n 1`;
} else {
	#$parm = `ls \$JESROOT/jessyslog/jessys.log.* | tail -n 1`;
	$parm = `ls -d rp/2019/* | tail -n 1`;
}

chomp $parm;

#old version, not in use any more!
#my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

printf(".. %s .. %s ..\n",$parm, $filter_date);

my @registo;
my ($start_time, $end_time, $work, $domain, $key) = ('', '', 0, '', '');

my $log_date;
my $log_time;
my $step_key;
my $tmp;

my $linhas = 0;

my $filename = basename($parm);
#$filename =~ /(\d+)/;
$filename = '/tmp/pkis/DIARY_XX_'. $name_2_file .'.csv';

open my $fpo,'>', $filename or die "ERROR $!\n";
printf($fpo "%s\n",$0);
printf($fpo "DATE_TIME;JOB_NUMBER;DOMAIN;JOB_NAME;STEP_NAME;");
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
	
	($log_date, $log_time) = (split(/\s/,$registo[DATA_HORA]));		
	
	$registo[START_TIME] =~ s/S//;
	$registo[END_TIME] =~ s/E//;	

	printf($fpo "%s;%s;%s;", $registo[DATA_HORA],$registo[JOB_NUMBER],$registo[DOMAIN]);
	printf($fpo "%s;%s;", $registo[JOB_NAME],$registo[STEP_NAME]);	
	printf($fpo "%s;%s;", $log_date .' '. $registo[START_TIME]
		, $log_date .' '. $registo[END_TIME]);
	
	if($registo[START_TIME] eq $registo[END_TIME]) {
		printf($fpo "%d",0);
	} else {
		$registo[START_TIME] = $log_date .' '. $registo[START_TIME];
		$registo[END_TIME] = $log_date .' '. $registo[END_TIME];	
		printf($fpo "%d", DateCalcFunctions::get_seconds_work_time(
			$registo[START_TIME],
			$registo[END_TIME]
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

