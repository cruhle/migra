#TUXJES_HOME_OFFICE.pl

#REGISTO DO FICHEIRO DE LOG
use constant	SERVER			=>	0;
use constant	DOMAIN			=>	1;
use constant	DATA_HORA		=>	2;
use constant	JOB_NUMBER		=>	3;
use constant	JOB_NAME		=>	4;
use constant	JOB_STATUS		=>	6;
use constant	RETURN_CODE		=>	7;
use constant	CLASS			=>	9;

use strict;
use warnings;
use integer;

use File::Basename;

use lib 'lib';
require DateCalcFunctions;

my @registo;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my $ficheiro = basename($parm);
$ficheiro =~ /(\d+)/;
$ficheiro = '/tmp/pkis/home_office_DOMAIN_'. $1 .'.csv';

my $fp;
my $domain;
my $tempo;

my %jobs;

open $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	
	next if($_ !~ /(STARTED|ENDED)/);
	@registo = split(/\t/);					
	
	#next if($registo[JOB_NAME] !~ /^PIFMFC/);
		
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
		
	$domain = $registo[DOMAIN];
	
	$jobs{$registo[JOB_NUMBER]}{$registo[JOB_STATUS]} = $registo[DATA_HORA];
	$jobs{$registo[JOB_NUMBER]}{'SERVER'} = $registo[SERVER];
	$jobs{$registo[JOB_NUMBER]}{'DOMAIN'} = $registo[DOMAIN];
	$jobs{$registo[JOB_NUMBER]}{'JOB_NAME'} = $registo[JOB_NAME];
	
	if($registo[JOB_STATUS] eq 'STARTED') {
		$jobs{$registo[JOB_NUMBER]}{'CLASS'} = $registo[CLASS];
	}
	
	if($registo[JOB_STATUS] eq 'ENDED') {
		$jobs{$registo[JOB_NUMBER]}{'RETURN_CODE'} = $registo[RETURN_CODE];
	}
}

close $fp;

$ficheiro =~ s/DOMAIN/$domain/g;

my %para_file;
my $key;

foreach(sort keys %jobs) {
	
	if(!exists($jobs{$_}{'STARTED'})) {
		printf("MISSING STARTED LABEL: %s %s %s\n"
		, $_, $jobs{$_}{'JOB_NAME'}, $jobs{$_}{'ENDED'} 
		);
		next;
	}
	
	if(!exists($jobs{$_}{'ENDED'})) {
		printf("MISSING END LABEL: %s %s %s\n"
		, $_, $jobs{$_}{'JOB_NAME'}, $jobs{$_}{'STARTED'} 
		);
		next;
	}		
	
	$tempo = DateCalcFunctions::get_seconds_work_time(
			$jobs{$_}{'STARTED'} , $jobs{$_}{'ENDED'} );
			
	$key = $domain .';'. (split(/\s/,$jobs{$_}{'STARTED'}))[0];
	
	$para_file{$key}{'counter'} += 1;
	$para_file{$key}{'total'} += $tempo;
	
}

open $fp,'>:unix', $ficheiro or die "ERROR $!\n";
printf($fp "%s\n",$0);
printf($fp "DOMAIN;DATE;COUNTER;RUNTIME_SECONDS;HH_MM\n");

foreach(sort keys %para_file) {

	printf($fp "%s;%d;%d;%s\n",
		$_,
		$para_file{$_}{'counter'},
		$para_file{$_}{'total'}
		,DateCalcFunctions::seconds_2_hh_mm_str($para_file{$_}{'total'})
	);
	
}

close $fp;

printf("%s\n",$ficheiro);




