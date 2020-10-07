#TUXJES_SLIM_FILE_DAILY.pl

#
#depois de correr o semanal por cada dominio
#a primeira corrida eh criado o ficheiro com sufixo aaaammdd
#todas as seguintes corridas o ficheiro eh anexado ao primeiro
#alterar o EOL para unix (CR/LF -> LF)
#renomear o ficheiro de dayly_aaaammdd.csv para dayly.csv
#usar como input para o TUXJES_DAILY_SUMMATY.pl
#que dara como output o DAILY_SUMMARY_aaaammdd.csv
#

#DESCRICAO DO REGISTO
#use constant	SERVIDOR	=>	0;
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
use constant	START_TIME	=>	6;
use constant	JOB_STATUS	=>	6;		#	SUBMITTED|AUTOPURGED|STARTED|ENDED
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

my $current_date = DateCalcFunctions::getCurrentDate();
my $filter_date = DateCalcFunctions::getYesterdayYYYY_MM_DD($current_date);
#$filter_date = aaaammdd

#forca estah data
#$filter_date='20191123';

my %output;
my $key;
my $work;

my @registo;
my $s_data;
my $e_data;

my ($in_lines, $out_lines) = (0,0);

my $ficheiro = '/tmp/pkis/DAILY_'. $filter_date .'.csv';

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	$in_lines++;

	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);
	next if(scalar @registo != 12);
	next if($registo[DATA_HORA] !~ /^$filter_date/);
	next if($registo[STEP_NAME] eq '-');
	next if(length($registo[START_TIME])!=9);
	next if(length($registo[END_TIME])!=9);	

	$s_data = (split(/\s/,$registo[DATA_HORA]))[0];
	$e_data = $s_data;
	
	$registo[START_TIME] =~ s/S//;	
	$registo[END_TIME] =~ s/E//;		
	
	if($registo[START_TIME] gt $registo[END_TIME]) {
		$s_data = DateCalcFunctions::getYesterdayYYYYMMDD($s_data);
	}
	
	$work = DateCalcFunctions::get_seconds_work_time(
			($s_data . ' ' . $registo[START_TIME]),
			($e_data . ' ' . $registo[END_TIME])
			);
	
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
		
	$key = $e_data .';'. $registo[DOMAIN] .';'. $registo[JOB_NUMBER];
	
	if(exists($output{$key})) {
		$output{$key}{'worktime'} += $work;
		if($output{$key}{'return_code'} eq 'C0000') {
			$output{$key}{'return_code'} = $registo[RETURN_CODE];
		}
	} else {
		$output{$key}{'worktime'} = $work;
		$output{$key}{'jobname'} = $registo[JOB_NAME];
		$output{$key}{'return_code'} = $registo[RETURN_CODE];
	}
			
}

close $fp;

if(!-e $ficheiro) {
	open $fp,'>', $ficheiro or die "ERROR $!\n";	
	printf($fp "%s\n",$0);
	printf($fp "DATE;DOMAIN;JOB_NUMBER;JOB_NAME;JOB_RUNTIME_SECONDS;RETURN_CODE\n");
} else {
	open $fp,'>>', $ficheiro or die "ERROR $!\n";
}


foreach(sort keys %output) {
	$out_lines++;
	printf($fp "%s;%s;%d;%s\n",
			$_,
			$output{$_}{'jobname'},
			$output{$_}{'worktime'},
			$output{$_}{'return_code'}
		);
}
close $fp;

printf("%s\n",$ficheiro);
printf("Lines read: %d, lines written: %d\n",$in_lines, $out_lines);
#------------------------------------------------------

##sub getDateFormated {
##
##	my $z = shift;
##	
##	$z =~ /^(\d{4})(\d{2})(\d{2})$/;
##	
##	return sprintf("%d-%02d-%02d", $1, $2, $3);
##}
