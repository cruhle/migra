#TUXJES_RCCounter.pl

#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog

use constant	DATA_HORA	  =>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	  =>	4;
use constant	STEP_NAME	  =>	5;
use constant	START_TIME	=>	6;
use constant	END_TIME	  =>	7;
use constant	RETURN_CODE	=>	11;

use strict;
use warnings;
use integer;

my ($parm) =  shift || die "Modo de uso: $0 ficheiro-log-erros\n"; 

my @ins;
my $code;
my %rcodes=();

open my $fp,'<',$parm or die "ERROR $!\n";
while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@ins = split(/\t/);
							
	#next if(scalar @ins != 12);
	next if($ins[STEP_NAME] eq '-');
	next if(substr($ins[JOB_NAME],1,1) eq 'T');
	
	$code = $ins[RETURN_CODE]; 	
	next if(substr($code,0,1) eq 'C' and substr($code,4,1) < 5);
  
	print;
	
	
	$rcodes{$code}+=1;		
  						
}
close $fp;

print "\nRC Counter value\n";

foreach(sort keys %rcodes) {
	printf("%s\t%d\n",$_, $rcodes{$_});
}

