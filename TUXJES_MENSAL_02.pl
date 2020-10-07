#TUXJES_MENSAL_02.pl

#
# INPUT = OUTPUT do TUXJES_MENSAL_01.pl
#

#DESCRICAO DO REGISTO
use constant	DATA		=>	0;
use constant	HORA		=>	1;
use constant	DOMAIN		=>	2;
use constant	JOB_RUNS	=>	3;
use constant	TOTAL_TIME	=>	4;

use strict;
use warnings;

use File::Basename;

my $ficheiro_de_entrada = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $ficheiro_de_entrada) {
	print "Ficheiro [$ficheiro_de_entrada] nao encontrado!\n";
	exit;
}

my $filter_date = $ficheiro_de_entrada;
$filter_date =~ /(\d{6})\.csv$/;
$filter_date = $1;

my %output;
my %jobs;

my $key;

my @registo;

my $ficheiro = '/tmp/pkis/MENSAL_'. $filter_date .'.csv';

open my $fp,'<',$ficheiro_de_entrada or die "ERROR $!\n";

while(<$fp>) {

	chomp;
	
	@registo = split(/;/);	
	
	$key = join(';',((split(/;/,$_))[0..2]));
#	print $key,"\n";	
	$output{$key}{'runs'} = $registo[JOB_RUNS];	
	$output{$key}{'total_time'} = $registo[TOTAL_TIME];	
	
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
	
	$key = join(';',((split(/;/,$_))[0..2]));
	#print $key,"\n";	
	if(exists($jobs{$key})) {
		$jobs{$key}{'counter'} += $output{$key}{'runs'};
		$jobs{$key}{'work'} += $output{$key}{'total_time'};
	} else {
		$jobs{$key}{'counter'} = $output{$key}{'runs'};
		$jobs{$key}{'work'} = $output{$key}{'total_time'};
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

foreach(sort keys %jobs) {		
		
	printf($fp "%s;%d;%d;%8.6f;%8.6f\n",
		$_,
		$jobs{$_}{'counter'},
		$jobs{$_}{'work'}
		, ($jobs{$_}{'counter'}>1?(($jobs{$_}{'counter'} - $miC) / ($mxC - $miC)):1)
		, ($jobs{$_}{'counter'}>1?(($jobs{$_}{'work'} - $miW) / ($mxW - $miW)):1)
	);
}


close $fp;

printf("%s\n",$ficheiro);


