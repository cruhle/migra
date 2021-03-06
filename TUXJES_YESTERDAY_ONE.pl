#TUXJES_YESTERDAY_ONE.pl

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

use strict;
use warnings;

use File::Basename;

use lib 'lib';
require DateCalcFunctions;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

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

my ($in, $out) = (0,0);
my %steps;

my $ficheiro = basename($parm);
$ficheiro =~ /(\d+)/;
$ficheiro = '/tmp/pkis/RAW_LOG_FILE_'. $m .'.csv';

open my $fp,'<',$parm or die "ERROR $!\n";

my $fpo;

if(!-e $ficheiro) {
	open $fpo,'>', $ficheiro or die "ERROR $!\n";
	printf($fpo "%s\n",$0);
	printf($fpo "SERVER;DATE_TIME;DOMAIN;JOB_NUMBER;JOB_NAME;STEP_NAME;");
	printf($fpo "STEP_NUMBER;STEP_START_TIME;STEP_END_TIME;");
	printf($fpo "STEP_RUNTIME_SECONDS;RETURN_CODE\n");	
} else {
	open $fpo,'>>', $ficheiro or die "ERROR $!\n";
}

while(<$fp>) {

	$in++;

	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);
	next if(scalar @registo != 12);
	
	next if($registo[STEP_NAME] eq '-');
	next if(length($registo[START_TIME])!=9);
	next if(length($registo[END_TIME])!=9);
	
	$data = (split(/\s/,$registo[DATA_HORA]))[0];
	
	next if($data ne $m);
				
	$start_time = substr($registo[START_TIME],1);
	$end_time = substr($registo[END_TIME],1);	
	
	$steps{$registo[JOB_NUMBER]}+=1;

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
	
	printf($fpo "%s;%s;%s;%s;%s;%s;%d;%s;%s;%d;%s\n",
		$registo[SERVIDOR],
		$registo[DATA_HORA],
		$registo[DOMAIN],
		$registo[JOB_NUMBER],
		$registo[JOB_NAME], 
		$registo[STEP_NAME],
		$steps{$registo[JOB_NUMBER]},
		$start_time,
		$end_time,
		$work,
		$registo[RETURN_CODE]
	);
	
	$out++;
}
close $fp;
close $fpo;

printf("%s in lines %d, out lines %d\n",$ficheiro, $in, $out);

#------------------------------------------------------
