#TUXJES_READ_CSV_HISTORY.pl

use strict;
use warnings;
#JOB_NUMBER;DOMAIN;JOB_NAME;DATA_SUBMITTED;DATA_STARTED;SECONDS_TO_START;DATA_ENDED;RUNTIME_SECONDS;RETURN_CODE
#DESCRICAO DO REGISTO
use constant	JOB_NUMBER			=>	0;
use constant	DOMAIN				=>	1;
use constant	JOB_NAME			=>	2;
use constant	DATA_SUBMITTED		=>	3;
use constant	DATA_STARTED		=>	4;
use constant	SECONDS_TO_START	=>	5;
use constant	DATA_ENDED			=>	6;
use constant	RUNTIME_SECONDS		=>	7;
use constant	RETURN_CODE			=>	8;

my ($parm) =  @ARGV; 

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my @registo;
my %valores;
my $key;

#printf("JOB_NAME;COUNTER;SECONDS_TO_START;RUNTIME_SECONDS\n");
open my $fp,'<',$parm or die "ERROR $!\n";
<$fp>;	#skip header row
while(<$fp>) {
	chomp;
	@registo = split(/;/);
	$key = $registo[JOB_NAME];
	
	if(exists($valores{$key})) {
		$valores{$key}{'counter'}+=1;
		$valores{$key}{'seconds_2_start'}+=$registo[SECONDS_TO_START];
		$valores{$key}{'runtime_seconds'}+=$registo[RUNTIME_SECONDS];
	} else {
		$valores{$key}{'counter'} = 1;
		$valores{$key}{'seconds_2_start'} = $registo[SECONDS_TO_START];
		$valores{$key}{'runtime_seconds'} = $registo[RUNTIME_SECONDS];
	}
	
}
close $fp;

foreach(sort keys %valores) {

	printf("%s;%d;%d;%d\n",
	$_,
	$valores{$_}{'counter'},
	$valores{$_}{'seconds_2_start'},
	$valores{$_}{'runtime_seconds'}
	);
}
