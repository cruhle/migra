#TUXJES_ValidaRC.pl

use constant	DOMAIN	 	 =>	1;
use constant	DATA_HORA	 =>	2;
use constant	JOB_NUMBER	 =>	3;
use constant	JOB_NAME	 =>	4;
use constant	STEP_NAME	 =>	5;
use constant	START_TIME	 =>	6;
use constant	END_TIME	 =>	7;
use constant	RETURN_CODE	 =>	11;

use strict;
use warnings;
use integer;

my ($parm) =  shift || die "Modo de uso: $0 ficheiro-log-erros\n"; 

my @registo;
my %code;
my $key;

open my $fp,'<',$parm or die "ERROR $!\n";
while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);
		
	next if(scalar @registo != 12);
	next if($registo[STEP_NAME] eq '-');
	
	$registo[DOMAIN] =~ s/BATCHPRD_//g;
		
	$key = getData($registo[DATA_HORA]) 
		.';'. $registo[DOMAIN]
		.';'. $registo[RETURN_CODE];
		
	$code{$key}+=1;
 		  					
}
close $fp;

foreach(sort keys %code) {
	printf("%s;%d\n", $_, $code{$_});
}

sub getData {

	my $x = shift;
	
	return (split(/\s/,$x))[0];
}

