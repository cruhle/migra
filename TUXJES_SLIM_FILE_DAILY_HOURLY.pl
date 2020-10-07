#TUXJES_SLIM_FILE_DAILY_HOURLY.pl

#
#depois de correr o semanal por cada dominio
#a primeira corrida eh criado o ficheiro com sufixo aaaammdd
#todas as seguintes corridas o ficheiro eh anexado ao primeiro
#alterar o EOL para unix (CR/LF -> LF)
#renomear o ficheiro de dayly_hourly_aaaammdd.csv para dayly.csv
#usar como input para o TUXJES_DAILY_SUMMATY.pl
#que dara como output o DAILY_SUMMARY_aaaammdd.csv
#

#DESCRICAO DO REGISTO
#use constant	SERVIDOR	=>	0;
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	STEP_NAME	=>	5;
use constant	JOB_STATUS	=>	6;		#	SUBMITTED|AUTOPURGED|STARTED|ENDED

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

my $current_date = DateCalcFunctions::getCurrentDate();
my $filter_date = DateCalcFunctions::getYesterdayYYYY_MM_DD($current_date);
#$filter_date = aaaammdd

#forca estah data
#$filter_date='20191123';

my %output;
my %jobs;

my $key;
my $work;

my @registo;
my $data;

my $hora;

my ($in_lines, $out_lines) = (0,0);

my $ficheiro = '/tmp/pkis/DAILY_HOURLY_'. $filter_date .'.csv';

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	$in_lines++;

	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);	
	
	next if($registo[DATA_HORA] !~ /^$filter_date/);
	
	next if($registo[JOB_STATUS] !~/(STARTED|ENDED)/);		
	
	$data = (split(/\s/,$registo[DATA_HORA]))[0];	
	$hora = (split(/\s/,$registo[DATA_HORA]))[1];
	$hora =~ /(\d{2})/;
	$hora = sprintf("%02d",$1);		
	
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
		
	$key = $data .';'. $registo[DOMAIN] .';'. $hora .';'. $registo[JOB_NUMBER];		
		
	$output{$key}{$registo[JOB_STATUS]} = $registo[DATA_HORA];	
	
}

close $fp;

if(!-e $ficheiro) {
	open $fp,'>', $ficheiro or die "ERROR $!\n";	
	printf($fp "%s\n",$0);
	printf($fp "DATE;DOMAIN;HORA;JOB_RUNS;RUNTIME_SECONDS\n");
} else {
	open $fp,'>>', $ficheiro or die "ERROR $!\n";
}

foreach(sort keys %output) {

	next if(!exists($output{$_}{'STARTED'}));
	next if(!exists($output{$_}{'ENDED'}));
	
	$work = DateCalcFunctions::get_seconds_work_time($output{$_}{'STARTED'}, $output{$_}{'ENDED'});
	
	$key = join(';',((split(/;/,$_))[0..2]));
	
	if(exists($jobs{$key})) {
		$jobs{$key}{'counter'} += 1;
		$jobs{$key}{'work'} += $work;
	} else {
		$jobs{$key}{'counter'} = 1;
		$jobs{$key}{'work'} = $work;
	}
	
	#$out_lines++;
	#printf("%s;%s;%s;%d\n",
	#		$_,
	#		$output{$_}{'STARTED'},
	#		$output{$_}{'ENDED'}
	#		,$work
	#	);
}

#my ($mxR, $miR, $mxT, $miT) = (0,99999,0,99999);
#foreach(sort keys %jobs) {	
#	
#	if($jobs{$_}{'counter'} > $mxR) {
#		$mxR = $jobs{$_}{'counter'};
#	}
#	if($jobs{$_}{'counter'} < $miR) {
#		$miR = $jobs{$_}{'counter'};
#	}
#
#	if($jobs{$_}{'work'} > $mxT) {
#		$mxT = $jobs{$_}{'work'};
#	}
#	if($jobs{$_}{'work'} < $miT) {
#		$miT = $jobs{$_}{'work'};
#	}
#	
#}

foreach(sort keys %jobs) {
	
	$out_lines++;
	
#	printf($fp "%s;%d;%d;\t%d;%d;%d;%d\n",
	printf($fp "%s;%d;%d\n",
		$_,
		$jobs{$_}{'counter'},
		$jobs{$_}{'work'}
#		,$mxR,$miR,$mxT,$miT
	);
}


close $fp;

#
printf("%s\n",$ficheiro);
printf("Lines read: %d, lines written: %d\n",$in_lines, $out_lines);
