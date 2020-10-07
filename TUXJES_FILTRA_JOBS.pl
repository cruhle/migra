#TUXJES_FILTRA_JOBS.pl

#/DEV/user/cobol_dv/load_csv

use strict;
use warnings;

#DESCRICAO DO REGISTO
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;

my ($parm) =  @ARGV; 

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my @registo;
my %jobs;

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);			
		
	next if(scalar @registo != 12);
	next if(length($registo[STEP_NAME]) eq '-');
			
	$jobs{$registo[JOB_NAME]} += 1;
}
close $fp;


foreach(sort keys %jobs) {
	printf("%s %d\n",$_, $jobs{$_});
}

