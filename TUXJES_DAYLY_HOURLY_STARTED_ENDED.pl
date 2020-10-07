printf("%03d\n",(localtime())[0]);

#TUXJES_DAYLY_HOURLY_STARTED_ENDED.pl

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
use constant	JOB_STATUS	=>	6;
use constant	RETURN_CODE	=>	7;

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
my ($domain, $key) = ('', 0);

my $jobs;

my $linhas = 0;

##`grep '$filter_date' $parm > ficheiro_tempor`;

my $filename = basename($parm);
#$filename =~ /(\d+)/;
$filename = '/tmp/pkis/DIARY_START_END_XX_'. $name_2_file .'.csv';

open my $fp,'<',$parm or die "ERROR $!\n";

##open my $fp,'<ficheiro_tempor' or die "ERROR $!\n";

my %jobs;

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	
	@registo = split(/\t/);						
	
	next if($registo[JOB_STATUS] !~ /^(STARTED|ENDED)/);	
	next if($registo[DATA_HORA] !~ /^$filter_date/);

	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	
	$domain = $registo[DOMAIN];
	
	$jobs{$registo[JOB_NUMBER]}{'SERVIDOR'} = $registo[SERVIDOR];
	$jobs{$registo[JOB_NUMBER]}{$registo[JOB_STATUS]} = $registo[DATA_HORA];
	$jobs{$registo[JOB_NUMBER]}{'DOMAIN'} = $registo[DOMAIN];
	$jobs{$registo[JOB_NUMBER]}{'JOB_NAME'} = $registo[JOB_NAME];
	
	if($registo[JOB_STATUS] eq 'ENDED') {
		$jobs{$registo[JOB_NUMBER]}{'RETURN_CODE'} = $registo[RETURN_CODE];
	}
}
close $fp;

open my $fpo,'>', $filename or die "ERROR $!\n";
printf($fpo "%s\n",$0);
printf($fpo "SERVER;DOMAIN;JOB_NUMBER;JOB_NAME;STARTED;");
printf($fpo "ENDED;JOB_RUNTIME_SECONDS;RETURN_CODE\n");

foreach(sort keys %jobs) {

	$linhas++;
	
	if(!exists($jobs{$_}{'STARTED'})) {
		$jobs{$_}{'STARTED'}='19700101 00:00:00';
	}
	
	if(!exists($jobs{$_}{'ENDED'})) {
		$jobs{$_}{'ENDED'}='19700101 00:00:00';
		$jobs{$_}{'RETURN_CODE'}='';
	}
	
	printf($fpo "%s;%s;%s;%s;%s;%s;",
		$jobs{$_}{'SERVIDOR'},
		$jobs{$_}{'DOMAIN'},
		$_,
		$jobs{$_}{'JOB_NAME'},		
		$jobs{$_}{'STARTED'},
		$jobs{$_}{'ENDED'}
	);
	
	if($jobs{$_}{'STARTED'} ne '19700101 00:00:00' and 
		$jobs{$_}{'ENDED'} ne '19700101 00:00:00') {
			printf($fpo "%d;",
			DateCalcFunctions::get_seconds_work_time(
				$jobs{$_}{'STARTED'},$jobs{$_}{'ENDED'})
			);
		} else { printf($fpo "%d;",0); }
	printf($fpo "%s\n",$jobs{$_}{'RETURN_CODE'});
	
}

close $fpo;

$fp = $filename;
$filename =~ s/XX/$domain/g;

rename($fp, $filename);
printf("%s %d\n",$filename, $linhas);
	
##unlink("ficheiro_tempor");

printf("%03d\n",(localtime())[0]);
