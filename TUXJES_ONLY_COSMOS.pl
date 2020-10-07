#TUXJES_ONLY_COSMOS.pl

#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog
#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT

#DESCRICAO DO REGISTO

use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
use constant	RETURN_CODE	=>	11;

use strict;
use warnings;
use integer;

my ($parm) =  @ARGV; # or die "Usage: $0 FICHEIRO\n";

if($#ARGV!=0) {
	printf("\nPARAMETROS\tERRO\tERRO\tERRO\t");
	printf("Faltam parametros: ficheiro\n");
	exit;
}

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my @ins;

my %returncodes;
my $key;
my $data;

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@ins = split(/\t/);
	next if(scalar @ins != 12);
	
	$returncodes{$ins[RETURN_CODE]}+=1;

	next if(substr($ins[JOB_NAME],1,1) eq 'T');
	next if(substr($ins[RETURN_CODE],0,1) eq 'C' and substr($ins[RETURN_CODE],4,1) < 5);

	$ins[DATA_HORA] =~ s/\s/\t/;
	printf("%s\t%s\t%s\t%-10s\t%s\n",
		$ins[DATA_HORA],
		$ins[JOB_NUMBER],
		$ins[JOB_NAME],
		$ins[STEP_NAME],
		$ins[RETURN_CODE]		
	);
	
}
close $fp;

print "\nRETURN CODES\n";

foreach(sort keys %returncodes) {
	printf("%-10s\t%d\n",$_, $returncodes{$_});
}