#TUXJES_PURGED_NOT_DELETED.pl

#REGISTO DO FICHEIRO DE LOG
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	JOB_STATUS	=>	6;

use strict;
use warnings;
use integer;

use File::Basename;

my @registo;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

my $ficheiro = basename($parm);
$ficheiro =~ /(\d+)/;
$ficheiro = '/tmp/pkis/PURGED_NOT_DELETED_XX_'. $1 .'.csv';

my $fp;
my $domain;

#----DELETED JOBS

my %deleted_jobs;
open $fp,'<','jobs_not_deleted_20191024.txt' or die "ERROR $!\n";
while(<$fp>) {
	chomp;
	$deleted_jobs{$_}=1;
}
close $fp;

#----DELETED JOBS

my %jobs;

open $fp,'<',$parm or die "ERROR $!\n";
printf("Reading %s ....\n",$parm);

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	
	next if($_ !~ /(SUBMITTED|AUTOPURGED|STARTED|ENDED)/);
	@registo = split(/\t/);					
		
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	
	$domain = $registo[DOMAIN];
	
	$jobs{$registo[JOB_NUMBER]}{$registo[JOB_STATUS]} = $registo[DATA_HORA];
	$jobs{$registo[JOB_NUMBER]}{'DOMAIN'} = $registo[DOMAIN];
	$jobs{$registo[JOB_NUMBER]}{'JOB_NAME'} = $registo[JOB_NAME];
			
}

close $fp;

$ficheiro =~ s/XX/$domain/g;


my ($counter, $writen) = (0 ,0);

open my $fpo,'>', $ficheiro or die "ERROR $!\n";
printf($fpo "%s\n",$0);
printf($fpo "JOB_NUMBER;JOB_NAME;DOMAIN;SUBMITTED;STARTED;ENDED;AUTOPURGED\n");

foreach(sort keys %jobs) {

	$counter++;
	next if(!exists($deleted_jobs{$_}));
	$writen++;
	
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
		#next;
	}
	if(!exists($jobs{$_}{'AUTOPURGED'})) {
		$jobs{$_}{'AUTOPURGED'}='19700101 00:00:00';
		#next;
	}
	
	printf($fpo "%s;%s;%s;%s;%s;%s;%s\n",
		$_,
		$jobs{$_}{'JOB_NAME'},
		$jobs{$_}{'DOMAIN'},
		$jobs{$_}{'SUBMITTED'},
		$jobs{$_}{'STARTED'},
		$jobs{$_}{'ENDED'},
		$jobs{$_}{'AUTOPURGED'}
	);
	

}

close $fpo;

printf("%s %d %d\n",$ficheiro, $counter, $writen);

