#TUXJES_STEPS_FILTER.pl

#REGISTO DO FICHEIRO DE LOG
use constant	JOB_NAME			=>	4;
use constant	STEP_NAME			=>	5;

use constant	PRINT_SQL_INSERT	=> 1;

use strict;
use warnings;
use integer;

my ($job_name, $parm) =  @ARGV; 

if (not defined $job_name) {
  die "Falta o nome do JOB para filtrar!\n";
}

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my @registo;
my %jobs;
my $contador = 0;
my $last_step = '';
$job_name = uc($job_name);

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);
		
	next if(scalar @registo != 12);
	
	next if($registo[JOB_NAME] ne $job_name);
	
	next if($registo[STEP_NAME] eq $last_step);
	
	$contador+=1;
	$last_step = $registo[STEP_NAME];
	
	if(PRINT_SQL_INSERT) {
		printf("insert into <TABELA> values('%s','%s',%d);\n",$registo[JOB_NAME], $registo[STEP_NAME], $contador);
	} else {
		printf("%s\t%d\t%s\n",$registo[JOB_NAME], $contador, $registo[STEP_NAME]);
	}
	
	last if($registo[STEP_NAME] eq 'END_JOB');
		
}

close $fp;



