#TUXJES_PURGED_V2_0.pl

#REGISTO DO FICHEIRO DE LOG
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	JOB_STATUS	=>	6;
use constant	RETURN_CODE	=>	7;

use strict;
use warnings;
use integer;

use File::Basename;

my @registo;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

my $ficheiro = basename($parm);
$ficheiro =~ /(\d+)/;
$ficheiro = '/tmp/pkis/PURGED_DATA_XX_'. $1 .'.csv';

my $fp;
my $domain;

#----DELETED JOBS

#my %deleted_jobs;
#open $fp,'<','deleted.jobs' or die "ERROR $!\n";
#while(<$fp>) {
#	chomp;
#	$deleted_jobs{$_}=1;
#}
#close $fp;

#----DELETED JOBS

my %jobs;

open $fp,'<',$parm or die "ERROR $!\n";
printf("Reading %s ....\n",$parm);

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	
	next if($_ !~ /(SUBMITTED|AUTOPURGED|STARTED|ENDED)/);
	@registo = split(/\t/);					
	
	#next if($registo[JOB_NAME] !~ /^PIFMFC/);
		
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	
	$domain = $registo[DOMAIN];
	
	$jobs{$registo[JOB_NUMBER]}{$registo[JOB_STATUS]} = $registo[DATA_HORA];
	$jobs{$registo[JOB_NUMBER]}{'DOMAIN'} = $registo[DOMAIN];
	$jobs{$registo[JOB_NUMBER]}{'JOB_NAME'} = $registo[JOB_NAME];
	
	if($registo[JOB_STATUS] eq 'ENDED') {
		$jobs{$registo[JOB_NUMBER]}{'RETURN_CODE'} = $registo[RETURN_CODE];
	}
			
}

close $fp;

$ficheiro =~ s/XX/$domain/g;

open my $fpo,'>', $ficheiro or die "ERROR $!\n";
printf($fpo "%s\n",$0);
printf($fpo "JOB_NUMBER;JOB_NAME;DOMAIN;SUBMITTED;STARTED;ENDED;AUTOPURGED;RETURN_CODE\n");

foreach(sort keys %jobs) {

	#next if(!exists($deleted_jobs{$_}));
	
	#next if(!exists($jobs{$_}{'RETURN_CODE'}));
	#next if($jobs{$_}{'RETURN_CODE'} ne 'S960');

	if(!exists($jobs{$_}{'SUBMITTED'})) {
		$jobs{$_}{'SUBMITTED'}='19700101 00:00:00';
		#next;
	}
	if(!exists($jobs{$_}{'STARTED'})) {
		$jobs{$_}{'STARTED'}='19700101 00:00:00';
		#next;
	}
	if(!exists($jobs{$_}{'ENDED'})) {
		$jobs{$_}{'ENDED'}='19700101 00:00:00';
		$jobs{$_}{'RETURN_CODE'}='';
		#next;
	}
	if(!exists($jobs{$_}{'AUTOPURGED'})) {
		$jobs{$_}{'AUTOPURGED'}='19700101 00:00:00';
		#next;
	}
	
	printf($fpo "%s;%s;%s;%s;%s;%s;%s;%s\n",
		$_,
		$jobs{$_}{'JOB_NAME'},
		$jobs{$_}{'DOMAIN'},
		$jobs{$_}{'SUBMITTED'},
		$jobs{$_}{'STARTED'},
		$jobs{$_}{'ENDED'},
		$jobs{$_}{'AUTOPURGED'},
		$jobs{$_}{'RETURN_CODE'}
	);
	

}

close $fpo;

printf("%s criado.\n",$ficheiro);

