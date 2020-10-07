#TUXJES_DEBUG.pl

use strict;
use warnings;
use integer;

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

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	printf("File [%s] not FOUND.\n",$parm);
	exit;
}

my @registo;

printf("[%s]\n",$parm);

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	chomp;	
	
	@registo = split(/\t/);		
	
	next if(scalar @registo != 12);
	next if($registo[STEP_NAME] eq '-');
	
	if(length($registo[START_TIME])!=9) {
		print $_,"\n";
	}
	if(length($registo[END_TIME])!=9) {
		print $_,"\n";
	}
	
	
		
}
close $fp;

