#TUXJES_PURGED_SUMMARY.pl

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
$ficheiro = '/tmp/pkis/PURGED_SUMMARY_XX_'. $1 .'.csv';

my $fp;
my $domain;

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

open $fp,'>', $ficheiro or die "ERROR $!\n";
printf($fp "%s\n",$0);
printf($fp "JOB_NUMBER;JOB_NAME;DOMAIN;SUBMITTED;STARTED;ENDED;AUTOPURGED;RETURN_CODE;STATUS\n");

my $status = 0;
my $counter=0;

foreach(sort keys %jobs) {

	$status = 0;
	$counter++;
	
	if(!exists($jobs{$_}{'SUBMITTED'})) {
		$jobs{$_}{'SUBMITTED'}='19700101 00:00:00';
		$status+=1;
	}

	if(!exists($jobs{$_}{'STARTED'})) {
		$jobs{$_}{'STARTED'}='19700101 00:00:00';
		$status+=1;
	}
	
	if(!exists($jobs{$_}{'ENDED'})) {
		$jobs{$_}{'ENDED'}='19700101 00:00:00';
		$jobs{$_}{'RETURN_CODE'}='';
		$status+=1;
	}
	
	if(!exists($jobs{$_}{'AUTOPURGED'})) {
		$jobs{$_}{'AUTOPURGED'}='19700101 00:00:00';
		$status+=1;
	}
	
	printf($fp "%s;%s;%s;%s;%s;%s;%s;%s;%d\n",
		$_,
		$jobs{$_}{'JOB_NAME'},
		$jobs{$_}{'DOMAIN'},
		$jobs{$_}{'SUBMITTED'},
		$jobs{$_}{'STARTED'},
		$jobs{$_}{'ENDED'},
		$jobs{$_}{'AUTOPURGED'},
		$jobs{$_}{'RETURN_CODE'},
		$status
	);
	

}

close $fp;

printf("%s %d\n",$ficheiro, $counter);




