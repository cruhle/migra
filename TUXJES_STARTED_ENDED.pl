#TUXJES_STARTED_ENDED.pl

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
require date_range_6d;

my @registo;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my $ficheiro = basename($parm);
$ficheiro =~ /(\d+)/;
$ficheiro = date_range_6d::getDateRange($1);
$ficheiro = '/tmp/pkis/XX_started_ended_'. $ficheiro .'.csv';

my $fp;
my $domain;

my %jobs;

open $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	
	next if($_ !~ /(STARTED|ENDED)/);
	@registo = split(/\t/);					
	
	#next if($registo[JOB_NAME] !~ /^PIFMFC/);
		
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	
	#QUALIDADE
	#$registo[DOMAIN] =~ s/BATCHDEV_//;	
	#next if($registo[JOB_NAME] !~ /^TITETS15$/);
	#QUALIDADE
	
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

$ficheiro =~ s/XX/$domain/g;

open $fp,'>:unix', $ficheiro or die "ERROR $!\n";
printf($fp "%s\n",$0);
printf($fp "SERVER;JOB_NUMBER;JOB_NAME;DOMAIN;CLASS;STARTED;ENDED;RUNTIME_SECONDS;RETURN_CODE\n");

my $status = 1;
my $complete = 1;

foreach(sort keys %jobs) {
	
	if(!exists($jobs{$_}{'STARTED'})) {
		$jobs{$_}{'STARTED'}='19700101 00:00:00';
		$jobs{$_}{'CLASS'} = '-';
		$status=0;
		$complete = 0;
	}
	
	if(!exists($jobs{$_}{'ENDED'})) {
		$jobs{$_}{'ENDED'}='19700101 00:00:00';
		$jobs{$_}{'RETURN_CODE'}='';
		$status=0;
		$complete = 0;
	}		
	
	if($status==1) {
		$status = DateCalcFunctions::get_seconds_work_time(
			$jobs{$_}{'STARTED'} , $jobs{$_}{'ENDED'} );
	}
	
	printf($fp "%s;%s;%s;%s;%s;%s;%s;%d;%s\n",
		$jobs{$_}{'SERVER'},
		$_,
		$jobs{$_}{'JOB_NAME'},
		$jobs{$_}{'DOMAIN'},
		$jobs{$_}{'CLASS'},
		showToDate($jobs{$_}{'STARTED'}),
		showToDate($jobs{$_}{'ENDED'}),
		$status,
		$jobs{$_}{'RETURN_CODE'}
	);
	
	$status = 1;
	$complete = 1;

}

close $fp;

printf("%s\n",$ficheiro);

#---------------------------------------------------

sub showToDate {

	my $x = shift;	

	$x =~ /(\d{4})(\d{2})(\d{2}) (.{8})/;

	return (sprintf("%04d-%02d-%02d %s" ,$1, $2, $3, $4));

}
