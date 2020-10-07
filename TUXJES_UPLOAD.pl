#TUXJES_UPLOAD.pl

use strict;
use warnings;
use integer;

#REGISTO DO FICHEIRO DE LOG
use constant	DOMAIN			=>	1;
use constant	DATA_HORA		=>	2;
use constant	JOB_NUMBER		=>	3;
use constant	JOB_STATUS		=>	6;
use constant	RETURN_CODE		=>	7;

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
$ficheiro = '/tmp/pkis/upload_XX_'. $1 .'.csv';

my $fp;
my $domain;
my $rec_tabs=0;
my %jobs;

open $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	
	next if($_ !~ /(STARTED|ENDED)/);
	@registo = split(/\t/);					
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	$rec_tabs = @registo;	
	$domain = $registo[DOMAIN];
	
	if($rec_tabs==15 and $registo[JOB_STATUS] eq 'STARTED') {
		$jobs{$registo[JOB_NUMBER]}{'DOMAIN'} = $registo[DOMAIN];
		$jobs{$registo[JOB_NUMBER]}{'STARTED'} = $registo[DATA_HORA];
	}
	
	if($rec_tabs==8 and $registo[JOB_STATUS] eq 'ENDED') {
		$jobs{$registo[JOB_NUMBER]}{'ENDED'} = $registo[DATA_HORA];
		$jobs{$registo[JOB_NUMBER]}{'RETURN_CODE'} = $registo[RETURN_CODE];
	}
}
close $fp;	

$ficheiro =~ s/XX/$domain/g;

open $fp,'>:unix', $ficheiro or die "ERROR $!\n";
#printf($fp "%s\n",$0);
printf($fp "JOB_NUMBER;DOMAIN;STARTED;ENDED;RUNTIME_SECONDS;RETURN_CODE\n");

foreach(sort keys %jobs) {
		
	next if(!exists($jobs{$_}{'STARTED'}));
	next if(!exists($jobs{$_}{'ENDED'}));

	$rec_tabs = DateCalcFunctions::get_seconds_work_time(
			$jobs{$_}{'STARTED'} , $jobs{$_}{'ENDED'} );
	
	
	printf($fp "%s;%s;%s;%s;%d;%s\n",
		$_,
		$jobs{$_}{'DOMAIN'},
		$jobs{$_}{'STARTED'},
		$jobs{$_}{'ENDED'},
		$rec_tabs,
		$jobs{$_}{'RETURN_CODE'}
	);	

}

close $fp;

printf("%s\n",$ficheiro);


