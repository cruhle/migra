#TUXJES_SEMANAL.pl

#cria ficheiro mensal

#sqlldr u_sugtmg_cruhle@tdbora4 control=load_jobs.ctl data=ficheiro-input

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
use constant	CLASS		=>	9;

use strict;
use warnings;

use File::Basename;

use lib 'lib';
require DateCalcFunctions;

my $filter_date = shift || die "Usage: $0 FILTER-DATE-YYYYMM LOG-FILE-TO-PROCESS\n";
my $ficheiro_de_entrada = shift || die "Usage: $0 FILTER-DATE-YYYYMM LOG-FILE-TO-PROCESS\n";

if(!-e $ficheiro_de_entrada) {
	print "Ficheiro [$ficheiro_de_entrada] nao encontrado!\n";
	exit;
}

my %output;
my %weekday;

my $key;

my @registo;

#my $data;
#my $hora;

my ($in_lines, $out_lines) = (0,0);

my $ficheiro = '/tmp/pkis/log_mensal_'. $filter_date .'.csv';

open my $fp,'<',$ficheiro_de_entrada or die "ERROR $!\n";

while(<$fp>) {

	$in_lines++;

	next if($_ !~ /^(cilene|dione)/);
	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);	
	
	#BIG QUESTION HERE
	#next if($registo[DATA_HORA] !~ /^$filter_date/);
	
	next if($registo[JOB_STATUS] !~/(STARTED|ENDED)/);		
	
	#$data = (split(/\s/,$registo[DATA_HORA]))[0];	
	#$hora = (split(/\s/,$registo[DATA_HORA]))[1];
	#$hora =~ /(\d{2})/;
	#$hora = sprintf("%02d",$1);		
	
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
				
	$key = $registo[DOMAIN] .';'. $registo[JOB_NUMBER] .';'. $registo[JOB_NAME];		
	
	$output{$key}{$registo[JOB_STATUS]} = $registo[DATA_HORA];	
	$output{$key}{'server'} = $registo[SERVER];	
	
	if($registo[JOB_STATUS] eq 'STARTED') {
		$output{$key}{'CLASS'} = $registo[CLASS];
	}
	
	if($registo[JOB_STATUS] eq 'ENDED') {
		$output{$key}{'RETURN_CODE'} = $registo[RETURN_CODE];	
	}
}

close $fp;

if(!-e $ficheiro) {
	open $fp,'>:unix', $ficheiro or die "ERROR $!\n";	
	printf($fp "%s\n",$0);
	printf($fp "SERVER;DOMAIN;JOB_NUMBER;JOB_NAME;JOB_CLASS;DAY_OF_WEEK;PART_OF_DAY;");
	printf($fp "JOB_STARTED;JOB_ENDED;");
	printf($fp "JOB_RUNTIME_SECONDS;RETURN_CODE\n");
} else {
	open $fp,'>>:unix', $ficheiro or die "ERROR $!\n";
}

##de yyyymm para yyyy
#$filter_date =~ /(\d{4})/;
#$filter_date = $1;	

foreach(sort keys %output) {

	#next if(!exists($output{$_}{'STARTED'}));
	#next if(!exists($output{$_}{'ENDED'}));	
	
	if(!exists($output{$_}{'STARTED'})) {
		print "STARTED ", $_ ,"\n";
		next;
	}
	
	if(!exists($output{$_}{'ENDED'})) {
		print "ENDED ",$_ ,"\n";
		next;
	}
	
	#if(($output{$_}{'STARTED'} !~ /^$filter_date/) and ($output{$_}{'ENDED'} !~ /^$filter_date/)) {
	if($output{$_}{'ENDED'} !~ /^$filter_date/) {
		#print "WRONG YEAR ",$_ ,"\t";
		#print $output{$_}{'STARTED'},"\t",$output{$_}{'ENDED'},"\n";
		next;
	}
	
	$output{$_}{'work'} = DateCalcFunctions::get_seconds_work_time($output{$_}{'STARTED'}, $output{$_}{'ENDED'});
				
	$out_lines++;
		
	printf($fp "%s;%s;%s;%d;%d;%s;%s;%d;%s\n",
		$output{$_}{'server'},
		$_,			#	domain, job number, job name
		$output{$_}{'CLASS'},
		getWeekDay($output{$_}{'STARTED'}),
		get_part_of_the_day($output{$_}{'STARTED'}),
		$output{$_}{'STARTED'},
		$output{$_}{'ENDED'},
		$output{$_}{'work'},
		$output{$_}{'RETURN_CODE'}
	);
		
}

close $fp;

printf("%s ",$ficheiro);
printf("lines in: %d, lines out: %d\n",$in_lines, $out_lines);

#-----------------------------------
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

#SQL_CREATE_TABLE create table TUXJES_JOBS (
#SQL_CREATE_TABLE     server char(6),
#SQL_CREATE_TABLE 	domain char(4),
#SQL_CREATE_TABLE     job_number number(8),
#SQL_CREATE_TABLE     job_name char(15),
#SQL_CREATE_TABLE 	day_of_week number(1),
#SQL_CREATE_TABLE 	part_of_day number(1),
#SQL_CREATE_TABLE 	job_started date,
#SQL_CREATE_TABLE 	job_ended date,
#SQL_CREATE_TABLE     job_runtime_seconds number(6),
#SQL_CREATE_TABLE     return_code char(5)
#SQL_CREATE_TABLE );


