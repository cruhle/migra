#TUXJES_MENSAL_00.pl

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

#my $ficheiro = 'TEMPORARIO_MENSAL_'. $filter_date .'.csv';

#my $ficheiro = '/tmp/pkis/month/MENSAL_00_'. $filter_date .'.csv';

my $ficheiro = '/tmp/pkis/month/logs_for_'. $filter_date .'.csv';

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
			
	#$key = $data .';'. $hora .';'. $registo[DOMAIN] .';'. $registo[JOB_NUMBER]
	#	.';'. $registo[JOB_NAME];		
	
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
	#printf($fp "DATE;TIME;DOMAIN;JOB_NUMBER;JOB_NAME;JOB_START;JOB_ENDED;RUNTIME_SECONDS;RETURN_CODE\n");
	printf($fp "SERVER;DOMAIN;JOB_NUMBER;JOB_NAME;DAY_OF_WEEK;PART_OF_DAY;JOB_START_TIME;JOB_END_TIME;RUNTIME_SECONDS;RETURN_CODE\n");
} else {
	open $fp,'>>', $ficheiro or die "ERROR $!\n";
}

#my %jobs;

foreach(sort keys %output) {

	next if(!exists($output{$_}{'STARTED'}));
	next if(!exists($output{$_}{'ENDED'}));
	
	$work = DateCalcFunctions::get_seconds_work_time($output{$_}{'STARTED'}, $output{$_}{'ENDED'});
	
	$output{$_}{'work'} = $work;
				
	$out_lines++;
		
	printf($fp "%s;%s;%d;%d;%s;%s;%d;%s\n",
		$output{$_}{'server'},
		$_,
		getWeekDay($output{$_}{'STARTED'}),
		get_part_of_the_day($output{$_}{'STARTED'}),
		format_date($output{$_}{'STARTED'}),
		format_date($output{$_}{'ENDED'}),
		$output{$_}{'work'},
		$output{$_}{'RETURN_CODE'}
	);
	
	#fica soh com o JOB_NAME
#	$key = (split(/;/,$_))[2];
#
#	if(exists($jobs{$key})) {
#		$jobs{$key}{'qtd'}+=1;
#		if($jobs{$key}{'max'} < $work) {
#			$jobs{$key}{'max'} = $work;
#		}
#		if($jobs{$key}{'min'} > $work) {
#			$jobs{$key}{'min'} = $work;
#		}
#	} else {
#		$jobs{$key}{'max'} = $work;
#		$jobs{$key}{'min'} = $work;
#		$jobs{$key}{'qtd'} = 1;
#	}
	
}

close $fp;

printf("%s ",$ficheiro);
printf("lines in: %d, lines out: %d\n",$in_lines, $out_lines);

#foreach(sort keys %jobs) {
#	printf("%s;%d;%d;%d\n",
#		$_,
#		$jobs{$_}{'qtd'},
#		$jobs{$_}{'min'},
#		$jobs{$_}{'max'}
#		#,($jobs{$_}{'max'} - $jobs{$_}{'min'}) / $jobs{$_}{'min'} * 100
#	);
#}
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

	$tmp =~ /(\d{4})(\d{2})(\d{2})\s(.{8})/;

	return sprintf("%4d-%02d-%02d %s",$1,$2,$3,$4);

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

