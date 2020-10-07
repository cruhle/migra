#TUXJES_AGRUPA_CSVS.pl

use strict;
use warnings;
use integer;

#DESCRICAO DO REGISTO
#DATA;JOBNAME;DOMAIN;JOBS;STEPS;TIME_SECONDS
use constant	DATA			=>	0;
use constant	JOBNAME			=>	1;
use constant	DOMAIN			=>	2;
use constant	JOBS			=>	3;
use constant	STEPS 			=>	4;
use constant	TIME_SECONDS	=>	5;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	printf("File [%s] not FOUND.\n",$parm);
	exit;
}

my @registo;
my %ficheiro;
my $key;

my ($ent, $sai) = (0,0);

open my $fp,'<',$parm or die "ERROR $!\n";
<$fp>;
while(<$fp>) {

	$ent++;
	

	chomp;	
	
	@registo = split(/;/);		
	
	$key = $registo[DATA] .';'. $registo[JOBNAME] .';'. $registo[DOMAIN];
	
	if(exists($ficheiro{$key})) {
#		printf("%s\n",$key);
		$ficheiro{$key}{'jobs'} += $registo[JOBS];
		$ficheiro{$key}{'steps'} += $registo[STEPS];
		$ficheiro{$key}{'segundos'} += $registo[TIME_SECONDS];
	} else {
		$ficheiro{$key} = {
			'jobs' => $registo[JOBS],
			'steps' => $registo[STEPS],
			'segundos' => $registo[TIME_SECONDS]
		};
	}
		
}
close $fp;

foreach(sort keys %ficheiro) {
	$sai++;
	printf("%s;%d;%d;%d\n",
		$_,
		$ficheiro{$_}{'jobs'},
		$ficheiro{$_}{'steps'},
		$ficheiro{$_}{'segundos'}
		);
}


#printf("%d-%d=%d\n",$ent, $sai, ($ent-$sai));



