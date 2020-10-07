#TUXJES_PURGED_V2.pl

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
$ficheiro = '/tmp/pkis/PURGED_DATA_XX_'. $1 .'.csv';

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
		
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	
	$domain = $registo[DOMAIN];
	
	$jobs{$registo[JOB_NUMBER]}{$registo[JOB_STATUS]} = $registo[DATA_HORA];
	$jobs{$registo[JOB_NUMBER]}{'DOMAIN'} = $registo[DOMAIN];
	$jobs{$registo[JOB_NUMBER]}{'JOB_NAME'} = $registo[JOB_NAME];
			
}

close $fp;

$ficheiro =~ s/XX/$domain/g;
open my $fpo,'>', $ficheiro or die "ERROR $!\n";
printf($fpo "%s\n",$0);
printf($fpo "JOB_NUMBER;JOB_NAME;DOMAIN;SUBMITTED;STARTED;ENDED;AUTOPURGED\n");

foreach(sort keys %jobs) {


	if(!exists($jobs{$_}{'SUBMITTED'})) {
		$jobs{$_}{'SUBMITTED'}='';
	}
	if(!exists($jobs{$_}{'STARTED'})) {
		$jobs{$_}{'STARTED'}='';
	}
	if(!exists($jobs{$_}{'ENDED'})) {
		$jobs{$_}{'ENDED'}='';
	}
	if(!exists($jobs{$_}{'AUTOPURGED'})) {
		$jobs{$_}{'AUTOPURGED'}='';
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
printf("%s criado.\n",$ficheiro);
