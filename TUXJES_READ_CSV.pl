#TUXJES_READ_CSV.pl

use strict;
use warnings;

#DESCRICAO DO REGISTO
use constant	DATA			=>	0;
use constant	DOMAIN			=>	1;
use constant	JOB_NUMBER		=>	2;
use constant	JOB_NAME		=>	3;
use constant	STEP_NAME		=>	4;
use constant	STEP_NUMBER		=>	5;
use constant	TIME_SECONDS	=>	6;
use constant	RETURN_CODE		=>	7;

my ($parm) =  @ARGV; 

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my %output;
my @registo;
my $key;
my $tempo = 0;
my $data;

open my $fp,'<',$parm or die "ERROR $!\n";
while(<$fp>) {
	chomp;
	@registo = split(/;/);
	next if($registo[RETURN_CODE] ne 'C0000');
	
	$key = $registo[JOB_NAME] .';'. $registo[STEP_NAME] .';'. $registo[STEP_NUMBER];
	$tempo = $registo[TIME_SECONDS];
	$data = $registo[DATA];
	
	if(exists($output{$key})) {
		$output{$key}{'counter'} += 1;
		if($output{$key}{'min'} > $tempo) {
			$output{$key}{'min'} = $tempo;
			$output{$key}{'min_data'} = $data;
			$output{$key}{'min_job_nbr'} = $registo[JOB_NUMBER];
		}
		if($output{$key}{'max'} < $tempo) {
			$output{$key}{'max'} = $tempo;
			$output{$key}{'max_data'} = $data;
			$output{$key}{'max_job_nbr'} = $registo[JOB_NUMBER];
		}
	} else {
		$output{$key}{'domain'} = $registo[DOMAIN];
		$output{$key}{'min'} = $tempo;
		$output{$key}{'min_data'} = $data;
		$output{$key}{'min_job_nbr'} = $registo[JOB_NUMBER];
		$output{$key}{'max'} = $tempo;
		$output{$key}{'max_data'} = $data;
		$output{$key}{'max_job_nbr'} = $registo[JOB_NUMBER];
		$output{$key}{'counter'} = 1;
	}
}
close $fp;

printf("JOB_NAME;STEP_NAME;STEP_NUMBER;DOMAIN;LOW_DATE;LOW_JOB;LOW_SECONDS;HIGH_DATE;HIGH_JOB;HIGH_SECONDS;MAX_MIN\n");

foreach(sort keys %output) {

	next if($output{$_}{'min'} == $output{$_}{'max'});
	
	next if($output{$_}{'max'} - $output{$_}{'min'} == 1);
	
	next if($output{$_}{'max'} - $output{$_}{'min'} < 1800);
	
	printf("%s;%s;%s;%s;%d;%s;%s;%d;%d\n",
		$_,
		$output{$_}{'domain'},
		$output{$_}{'min_data'},
		$output{$_}{'min_job_nbr'},
		$output{$_}{'min'},
		$output{$_}{'max_data'},
		$output{$_}{'max_job_nbr'},
		$output{$_}{'max'},
		$output{$_}{'max'}-$output{$_}{'min'}
		);
}

