#TUXJES_STEP_SIZE.pl

use strict;
use warnings;
use integer;

use warnings FATAL => 'all';

#DESCRICAO DO REGISTO

use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	printf("File [%s] not FOUND.\n",$parm);
	exit;
}

my @registo;

my ($maxSTEP, $maxJOB, $step, $job) = (0,0,'','');

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	next if(/SUBMITTED/);
	next if(/STARTED/);
	next if(/AUTOPURGED/);
	next if(/ENDED/);
	chomp;	
	
	@registo = split(/\t/);		
	next if(scalar @registo != 12);
	next if($registo[JOB_NAME] eq '-');
	next if($registo[STEP_NAME] eq '-');
	
	if(length($registo[JOB_NAME])>$maxJOB) {
		$maxJOB = length($registo[JOB_NAME]);
		$job = $registo[JOB_NAME];
	}
	
	if(length($registo[STEP_NAME])>$maxSTEP) {
		$maxSTEP = length($registo[STEP_NAME]);
		$step = $registo[STEP_NAME];
	}		
		
}
close $fp;

#printf("[%s] [%s][%d] - [%s][%d]\n", $parm, $job, $maxJOB, $step, $maxSTEP);

printf("%s %d - %s %d\n",$job, $maxJOB, $step, $maxSTEP);



