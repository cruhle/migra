#TUXJES_MENSAL.pl

#
#
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

my $ficheiro_de_entrada = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $ficheiro_de_entrada) {
	print "Ficheiro [$ficheiro_de_entrada] nao encontrado!\n";
	exit;
}

#mes para filtrar YYYYMM
my $filter_date = '201910';

my %output;
my %jobs;

my $key;
my $work;

my @registo;
my $data;

my $hora;

my ($in_lines, $out_lines) = (0,0);

my $ficheiro = '/tmp/pkis/MENSAL_'. $filter_date .'.csv';

open my $fp,'<',$ficheiro_de_entrada or die "ERROR $!\n";

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
				
	$key = $data .';'. $hora .';'. $registo[DOMAIN] .';'. $registo[JOB_NUMBER];		
	
	$output{$key}{$registo[JOB_STATUS]} = $registo[DATA_HORA];	
	
}

close $fp;

if(!-e $ficheiro) {
	open $fp,'>', $ficheiro or die "ERROR $!\n";	
	printf($fp "%s\n",$0);
	printf($fp "DATE;TIME;DOMAIN;JOB_RUNS;RUNTIME_SECONDS;GRAPH_RUNS;GRAPH_SECONDS\n");
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
	
}

my ($mxC, $miC, $mxW, $miW) = (1,99999,1,99999);
foreach(sort keys %jobs) {	
	
	if($jobs{$_}{'counter'} > $mxC) {
		$mxC = $jobs{$_}{'counter'};
	}
	if($jobs{$_}{'counter'} < $miC) {
		$miC = $jobs{$_}{'counter'};
	}

	if($jobs{$_}{'work'} > $mxW) {
		$mxW = $jobs{$_}{'work'};
	}
	if($jobs{$_}{'work'} < $miW) {
		$miW = $jobs{$_}{'work'};
	}
	
}

#printf("MIC %d - MXC %d - MIW %d - MXW %d\n",
#	$miC, 	$mxC, 	$miW, 	$mxW );

foreach(sort keys %jobs) {
	
	$out_lines++;
	
	#printf("(%s) counter(%d) work(%d)\n",
	#	$_,
	#	$jobs{$_}{'counter'},
	#	$jobs{$_}{'work'}
	#);
	
	printf($fp "%s;%d;%d;%8.6f;%8.6f\n",
		$_,
		$jobs{$_}{'counter'},
		$jobs{$_}{'work'}
		, ($jobs{$_}{'counter'}>1?(($jobs{$_}{'counter'} - $miC) / ($mxC - $miC)):1)
		, ($jobs{$_}{'counter'}>1?(($jobs{$_}{'work'} - $miW) / ($mxW - $miW)):1)
	);
}


close $fp;

#
printf("%s\n",$ficheiro);
printf("Lines read: %d, lines written: %d\n",$in_lines, $out_lines);
