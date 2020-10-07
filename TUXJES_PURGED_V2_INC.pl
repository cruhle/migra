#TUXJES_PURGED_V2_INC.pl

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
$ficheiro = '/tmp/pkis/PURGED_DATA0_XX_'. $1 .'.csv';
#_inc => incompleto, nem todos os campos preenchidos
my $ficheiro_inc = '/tmp/pkis/PURGED_DATA0_INC_XX_'. $1 .'.csv';

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
$ficheiro_inc =~ s/XX/$domain/g;

open my $fpo,'>', $ficheiro or die "ERROR $!\n";
printf($fpo "%s\n",$0);
printf($fpo "JOB_NUMBER;JOB_NAME;DOMAIN;SUBMITTED;STARTED;ENDED;AUTOPURGED;RETURN_CODE\n");

open my $fpo_inc,'>', $ficheiro_inc or die "ERROR $!\n";
printf($fpo_inc "%s\n",$0);
printf($fpo_inc "JOB_NUMBER;JOB_NAME;DOMAIN;SUBMITTED;STARTED;ENDED;AUTOPURGED;RETURN_CODE\n");

my $status = 1;

my ($counter_compl, $counter_inc) = (0,0);

foreach(sort keys %jobs) {

	$status = 1;
	
	if(!exists($jobs{$_}{'SUBMITTED'})) {
		$jobs{$_}{'SUBMITTED'}='19700101 00:00:00';
		$status=0;
	}
	if(!exists($jobs{$_}{'STARTED'})) {
		$jobs{$_}{'STARTED'}='19700101 00:00:00';
		$status=0;
	}
	if(!exists($jobs{$_}{'ENDED'})) {
		$jobs{$_}{'ENDED'}='19700101 00:00:00';
		$jobs{$_}{'RETURN_CODE'}='';
		$status=0;
	}
	if(!exists($jobs{$_}{'AUTOPURGED'})) {
		$jobs{$_}{'AUTOPURGED'}='19700101 00:00:00';
		$status=0;
	}

	if($status==1) {
		$counter_compl += 1;
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
	} else {
		$counter_inc += 1;
		printf($fpo_inc "%s;%s;%s;%s;%s;%s;%s;%s\n",
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

}

close $fpo;
close $fpo_inc;

printf("COMPLETO:   %s %d\n",$ficheiro, $counter_compl);
printf("INCOMPLETO: %s %d\n",$ficheiro_inc, $counter_inc);

