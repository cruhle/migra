#TUXJES_UPLOAD_27N.pl

use strict;
use warnings;
use integer;

#REGISTO DO FICHEIRO DE LOG
use constant	DOMAIN			=>	1;
use constant	DATA_HORA		=>	2;
use constant	JOB_NUMBER		=>	3;
use constant	JOB_NAME		=>	4;
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
$ficheiro = '/tmp/pkis/upload_27N_XX_'. $1 .'.csv';

my $ficheiro_names = '/tmp/pkis/upload_27N_NM_XX_'. $1 .'.csv';

my $ficheiro_jobs  = '/tmp/pkis/upload_27N_JOBS_XX_'. $1 .'.csv';
my $key;
my %joblist;

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
		$jobs{$registo[JOB_NUMBER]}{'JOBNAME'} = $registo[JOB_NAME];
	}
	
	if($rec_tabs==8 and $registo[JOB_STATUS] eq 'ENDED') {
		$jobs{$registo[JOB_NUMBER]}{'ENDED'} = $registo[DATA_HORA];
		$jobs{$registo[JOB_NUMBER]}{'RETURN_CODE'} = $registo[RETURN_CODE];
	}
	
	$key = $registo[DOMAIN] .';'. $registo[JOB_NAME];
	$joblist{$key}=1;
}
close $fp;	

$ficheiro =~ s/XX/$domain/g;
$ficheiro_names =~ s/XX/$domain/g;
$ficheiro_jobs =~ s/XX/$domain/g;

open $fp,'>:unix', $ficheiro or die "ERROR $!\n";
#printf($fp "%s\n",$0);
printf($fp "JOB_NUMBER;DOMAIN;JOB_NAME;STARTED;ENDED;RUNTIME_SECONDS;RETURN_CODE\n");

open my $fpn,'>:unix',$ficheiro_names or die "ERROR $!\n";
printf($fpn "JOB_NUMBER;DOMAIN;JOB_NAME\n");

my $linhas = 0;

foreach(sort keys %jobs) {
		
	next if(!exists($jobs{$_}{'STARTED'}));
	next if(!exists($jobs{$_}{'ENDED'}));

	$rec_tabs = DateCalcFunctions::get_seconds_work_time(
			$jobs{$_}{'STARTED'} , $jobs{$_}{'ENDED'} );
	
	
	printf($fp "%s;%s;%s;%s;%s;%d;%s\n",
		$_,
		$jobs{$_}{'DOMAIN'},
		$jobs{$_}{'JOBNAME'},
		DateCalcFunctions::converteData2PowerBI($jobs{$_}{'STARTED'}),
		DateCalcFunctions::converteData2PowerBI($jobs{$_}{'ENDED'}),
		$rec_tabs,
		$jobs{$_}{'RETURN_CODE'}
	);	
	
	printf($fpn "%s;%s;%s\n",
		$_,
		$jobs{$_}{'DOMAIN'},
		$jobs{$_}{'JOBNAME'}
	);
	
	$linhas+=1;

}

close $fp;
close $fpn;

printf("Nr Linhas p/ficheiro: %d\n",$linhas);
printf("%s\n",$ficheiro);
printf("%s\n",$ficheiro_names);

$linhas=0;
open $fp,'>:unix',$ficheiro_jobs or die "ERROR $!\n";
printf($fp "DOMAIN;JOB_NAME\n");

$linhas = 0;

foreach(sort keys %joblist) {
	printf($fp "%s\n",$_);
	$linhas+=1;
}

close $fp;
printf("Nr Linhas p/ficheiro: %d\n",$linhas);
printf("%s\n",$ficheiro_jobs);


