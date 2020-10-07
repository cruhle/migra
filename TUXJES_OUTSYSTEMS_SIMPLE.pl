#TUXJES_OUTSYSTEMS_SIMPLE.pl

#cria ficheiro mensal
#para ser lido pelo tuxjes_simple_one.pl

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

use Time::Piece;
use File::Basename;

use lib 'lib';
require DateCalcFunctions;

my $ficheiro_de_entrada = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $ficheiro_de_entrada) {
	print "Ficheiro [$ficheiro_de_entrada] nao encontrado!\n";
	exit;
}

my %output;
my %weekday;

my $key;
my $domain;

my @registo;

my ($in_lines, $out_lines) = (0,0);

my $ficheiro = basename($ficheiro_de_entrada);
$ficheiro =~ /(\d+)/;
$ficheiro = '/tmp/pkis/log_os_XX_clean_'. $1 .'.csv';
my $filter_date = $1;
$filter_date =~ /(\d{2})(\d{2})(\d{2})/;
$filter_date = ($3 + 2000).''.$1.''.$2;

open my $fp,'<',$ficheiro_de_entrada or die "ERROR $!\n";

while(<$fp>) {

	$in_lines++;

	next if($_ !~ /^(cilene|dione)/);
	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);	
	
	next if($registo[JOB_STATUS] !~/(STARTED|ENDED)/);		
	#next if($registo[RETURN_CODE] !~ /^C\d{4}$/);
	
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	$domain = $registo[DOMAIN];
	
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

$ficheiro =~ s/XX/$domain/g;

#if(!-e $ficheiro) {
	open $fp,'>:unix', $ficheiro or die "ERROR $!\n";	
	printf($fp "%s\n",$0);
	printf($fp "JOB_DATE;DOMAIN;JOB_NAME;JOB_CLASS;PART_OF_DAY;");
	printf($fp "JOB_RUNTIME_SECONDS;RETURN_CODE\n");
#} else {
#	open $fp,'>>:unix', $ficheiro or die "ERROR $!\n";
#}

foreach(sort keys %output) {
	
	if(!exists($output{$_}{'STARTED'})) {
		#print "STARTED ", $_ ,"\n";
		next;
	}
	
	if(!exists($output{$_}{'ENDED'})) {
		#print "ENDED ",$_ ,"\n";
		next;
	}
		
	$output{$_}{'work'} = DateCalcFunctions::get_seconds_work_time($output{$_}{'STARTED'}, $output{$_}{'ENDED'});
				
	$out_lines++;
		
	printf($fp "%s;%s;%s;%s;%d;%d;%s\n",
		getStartedDate($output{$_}{'STARTED'}),		
		(split(/;/,$_))[0],			#DOMAIN
		(split(/;/,$_))[2],			#JOB_NAME
		$output{$_}{'CLASS'},
		get_part_of_the_day($output{$_}{'STARTED'}),		
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

sub getStartedDate {

	my $tmp = shift;
	
	$tmp =~ /(\d{4})(\d{2})(\d{2}) (\d{2})/;	
	$tmp = $1.'-'.$2.'-'.$3.' '.$4.':00:00';
	
	return $tmp;
	
}


