#TUXJES_YESTERDAY_SEMANAL_STRIP.pl

#part_of_the_day
#00-05	1		madrugada
#06-11	2		manha
#12-17	3		tarde
#18-23	4		noite

#DESCRICAO DO REGISTO
use constant	SERVER		=>	0;
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
use constant	JOB_STATUS	=>	6;		#	STARTED|ENDED
use constant	RETURN_CODE	=>	7;

use strict;
use warnings;

use File::Basename;

use lib 'lib';
require DateCalcFunctions;

my $ficheiro_de_entrada = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $ficheiro_de_entrada) {
	print "Ficheiro [$ficheiro_de_entrada] nao encontrado!\n";
	exit;
}

#yesterday
my ($d, $m, $y) = (localtime())[3..5];
$y+=1900;
$m++;
$y = sprintf("%4d%02d%02d",$y, $m, $d);
$m = DateCalcFunctions::getYesterdayYYYYMMDD($y);
#to change the date
#$m='20191222';

my %output;
my %weekday;

my $key;

my @registo;

my $data;

my ($in_lines, $out_lines) = (0,0);

my $ficheiro = '/tmp/pkis/raw_log_agrupado_'. $m .'.csv';

open my $fp,'<',$ficheiro_de_entrada or die "ERROR $!\n";

while(<$fp>) {

	$in_lines++;

	next if($_ !~ /^(cilene|dione)/);
	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);	
	
	$data = (split(/\s/,$registo[DATA_HORA]))[0];	
	next if($data !~ /^$m$/);
	
	next if($registo[JOB_STATUS] !~/(STARTED|ENDED)/);		
		
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
				
	$key = $registo[DOMAIN] .';'. $registo[JOB_NUMBER] .';'. $registo[JOB_NAME];		
	
	$output{$key}{$registo[JOB_STATUS]} = $registo[DATA_HORA];	
	$output{$key}{'server'} = $registo[SERVER];	
	
	if($registo[JOB_STATUS] eq 'ENDED') {
		$output{$key}{'RETURN_CODE'} = $registo[RETURN_CODE];	
	}
}

close $fp;

if(!-e $ficheiro) {
	open $fp,'>', $ficheiro or die "ERROR $!\n";	
	printf($fp "%s\n",$0);
	printf($fp "SERVER;DOMAIN;JOB_NUMBER;JOB_NAME;DAY_OF_WEEK;PART_OF_DAY;");
	printf($fp "JOB_STARTED_HOUR;");
	printf($fp "JOB_STARTED_DATE;");
	printf($fp "JOB_RUNTIME_SECONDS;RETURN_CODE\n");
} else {
	open $fp,'>>', $ficheiro or die "ERROR $!\n";
}

foreach(sort keys %output) {

	next if(!exists($output{$_}{'STARTED'}));
	next if(!exists($output{$_}{'ENDED'}));	
		
	$output{$_}{'work'} = DateCalcFunctions::get_seconds_work_time($output{$_}{'STARTED'}, $output{$_}{'ENDED'});
				
	$out_lines++;
		
	printf($fp "%s;%s;%d;%d;%d;%s;%d;%s\n",
		$output{$_}{'server'},
		$_,			#	domain, job number, job name
		getWeekDay($output{$_}{'STARTED'}),
		get_part_of_the_day($output{$_}{'STARTED'}),
		hora($output{$_}{'STARTED'}),
		data($output{$_}{'STARTED'}),
		$output{$_}{'work'},
		$output{$_}{'RETURN_CODE'}
	);
		
}

close $fp;

printf("%s ",$ficheiro);
printf("lines in: %d, lines out: %d\n",$in_lines, $out_lines);

#-----------------------------------
sub hora {
	my $tmp = shift;
	$tmp =~ /(\d{8}) (\d{2})/;
	return $2;
}

sub data {
	my $tmp = shift;
	$tmp =~ /(\d{8}) (\d{2})/;
	return $1;
}

sub get_part_of_the_day {

	my $tmp = shift;

	$tmp =~ /(\d{8}) (\d{2})/;

	$tmp=$2;
	return ($tmp<6?1:($tmp<12?2:($tmp<18?3:4)));
}

sub format_date {

	my $tmp = shift;

	$tmp =~ /(\d{4})(\d{2})(\d{2})\s(.+)/;
	
	return sprintf("%04d-%02d-%02d %s",$1,$2,$3,$4);
}

sub getWeekDay {

	my $tmp = shift;
	$tmp = (split(/\s/,$tmp))[0];

	if(!exists($weekday{$tmp})) {
		# ano mes dia
		$tmp =~ /(\d{4})(\d{2})(\d{2})/;
		$weekday{$tmp} = DateCalcFunctions::getWeekday($1,$2,$3);
	}
	
	return $weekday{$tmp};			

}

#SQL_CREATE_TABLE create table TUXJES_DAY (
#SQL_CREATE_TABLE     server char(6),
#SQL_CREATE_TABLE 	domain char(4),
#SQL_CREATE_TABLE     job_number number(8),
#SQL_CREATE_TABLE     job_name char(15),
#SQL_CREATE_TABLE 	day_of_week number(1),
#SQL_CREATE_TABLE 	part_of_day number(1),
#SQL_CREATE_TABLE 	job_started_hour number(2),
#SQL_CREATE_TABLE 	job_started_date number(8),
#SQL_CREATE_TABLE 	--job_started date,
#SQL_CREATE_TABLE 	--job_ended date,
#SQL_CREATE_TABLE     job_runtime_seconds number(6),
#SQL_CREATE_TABLE     return_code char(5)
#SQL_CREATE_TABLE );


