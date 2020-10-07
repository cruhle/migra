#TUXJES_MENSAL_MICROSTRATEGY.pl

#
# OUTPUT vai servir de INPUT para TUXJES_MENSAL_02.pl
#
#dir misc /s/b /a-d /on
#

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
use constant	JOB_STATUS	=>	6;		#	SUBMITTED|AUTOPURGED|STARTED|ENDED
use constant	RETURN_CODE	=>	7;

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

#mes para filtrar YYYYMM
#$filter_date = '201902';

my %output;
my %weekday;

my $key;
my $work;

my @registo;
my $data;

my $hora;

my ($in_lines, $out_lines) = (0,0);

my $ficheiro = '/tmp/pkis/microstrategy/tuxjes_log_'. $filter_date .'.csv';

open my $fp,'<',$ficheiro_de_entrada or die "ERROR $!\n";

while(<$fp>) {

	$in_lines++;

	next if($_ !~ /^(cilene|dione)/);
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
	#printf($fp "JOB_YEAR;JOB_MONTH;JOB_DAY;JOB_HOUR;");
	printf($fp "JOB_START_DATE;");
	printf($fp "RUNTIME_SECONDS;RETURN_CODE\n");
} else {
	open $fp,'>>', $ficheiro or die "ERROR $!\n";
}


foreach(sort keys %output) {

	next if(!exists($output{$_}{'STARTED'}));
	next if(!exists($output{$_}{'ENDED'}));
	
	$work = DateCalcFunctions::get_seconds_work_time($output{$_}{'STARTED'}, $output{$_}{'ENDED'});
	
	$output{$_}{'work'} = $work;
				
	$out_lines++;
		
	printf($fp "%s;%s;%d;%d;%s;%d;%s\n",
		$output{$_}{'server'},
		$_,
		getWeekDay($output{$_}{'STARTED'}),
		get_part_of_the_day($output{$_}{'STARTED'}),
		format_date($output{$_}{'STARTED'}),
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
	#$tmp = ($x<6?1:($x<12?2:($x<18?3:4)));
	#return $tmp;
	return ($tmp<6?1:($tmp<12?2:($tmp<18?3:4)));
}

sub format_date {

	my $tmp = shift;

	$tmp =~ /(\d{4})(\d{2})(\d{2})\s(.+)/;
	
#	$1	ano
#	$2	mes
#	$3	dia
#	$4	hh:mm:ss
	
#	$tmp =~ /(\d{4})(\d{2})(\d{2})\s(\d{2})/;

#	$1	ano
#	$2	mes
#	$3	dia
#	$4	hora hh

#a 2 espacos
#	return sprintf("%4d;%02d;%02d;%02d",$1,$2,$3,$4);

#sem numero de espacos
#	return sprintf("%d;%d;%d;%d",$1,$2,$3,$4);

#data formatada + hh
#	return sprintf("%04d-%02d-%02d;%d",$1,$2,$3,$4);
	
#timestamp format	
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

