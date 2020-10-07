#TUXJES_VALDAR_STEPS.pl

use strict;
use warnings;

#DESCRICAO DO REGISTO
use constant	SERVIDOR	=>	0;
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
use constant	START_TIME	=>	6;
use constant	END_TIME	=>	7;
use constant	RETURN_CODE	=>	11;

my ($parm) =  @ARGV; 

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my @registo;
my $size;
my %tamanhos;

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	chomp;
	@registo = split(/\t/);
	
	next if(!/(\sAUTOPURGED\s)/);
	
	
	$size = @registo;
	$tamanhos{$size} +=1;
	
	#if($size==14) {
	#	print;
	#	print "\n";
	#}
	
}
close $fp;

foreach(sort keys %tamanhos) {
	printf("%d %d\n",$_, $tamanhos{$_})
}

