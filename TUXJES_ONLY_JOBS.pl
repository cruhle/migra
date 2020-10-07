#TUXJES_ONLY_JOBS.pl
#job counter per day only

#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog
#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT

#DESCRICAO DO REGISTO

use constant	JOB_DATE	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	JOB_STEP	=>	5;
use constant	JOB_START	=>	6;
use constant	JOB_END		=>	7;

use strict;
use warnings;
use integer;

my ($parm) =  @ARGV; # or die "Usage: $0 FICHEIRO\n";

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my %jobsnames;
my $jobsname;
my $jobdate;

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	next if(/(AUTOPURGED|SUBMITTED)/);			
	
	if(/START/) {
		if(!/START$/) {
			$jobdate  = (split(/\s/,(split(/\t/))[JOB_DATE]))[0];
			$jobsname = (split(/\t/))[JOB_NAME];
			$jobsnames{$jobdate . ';' . $jobsname}+=1;
		}
	}
		
}
close $fp;

foreach(sort keys %jobsnames) {
	printf("%s;%d\n",$_, $jobsnames{$_});
}


