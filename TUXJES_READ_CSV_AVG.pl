#TUXJES_READ_CSV_AVG.pl

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
		$output{$key}{'work_time'} += $tempo;
	} else {
		$output{$key}{'work_time'} = $tempo;
		$output{$key}{'counter'} = 1;
		$output{$key}{'domain'} = $registo[DOMAIN];
	}
}
close $fp;

printf("JOB_NAME;STEP_NAME;STEP_NUMBER;DOMAIN;COUNTER;TIME_SECONDS;AVG\n");

foreach(sort keys %output) {

	#next if($output{$_}{'work_time'} == 0);
	
	next if($output{$_}{'work_time'} < 11);
	
	next if($output{$_}{'work_time'} / $output{$_}{'counter'} < 1801);

	printf("%s;%s;%d;%d;%5.2f\n",
		$_,
		$output{$_}{'domain'},
		$output{$_}{'counter'},
		$output{$_}{'work_time'}		
		,($output{$_}{'work_time'}/$output{$_}{'counter'})
		);
}

