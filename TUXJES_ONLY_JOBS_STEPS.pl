#TUXJES_ONLY_JOBS_TIME.pl

#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog
#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT

#DESCRICAO DO REGISTO

use constant	JOB_DATE	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	JOB_STEP	=>	5;
use constant	JOB_START	=>	6;
use constant	JOB_END		=>	7;

use strict;
use warnings;
use integer;

my ($parm) =  @ARGV; # or die "Usage: $0 FICHEIRO\n";

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my %jobs;

my $jobdate;
my $jobnumber;
my $jobname;
my $jobstep;
my $jobstart;
my $jobend;

my $key;
my $step;

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	next if(/(AUTOPURGED|SUBMITTED)/);	
	
	$jobstep = (split(/\t/))[JOB_STEP];
	next if($jobstep !~ /^[A-Z0-9_]+$/);
	
	$jobdate  = (split(/\s/,(split(/\t/))[JOB_DATE]))[0];
	$jobnumber = (split(/\t/))[JOB_NUMBER];
	$jobname = (split(/\t/))[JOB_NAME];
	
	$jobstart = (split(/\t/))[JOB_START];
	$jobend = (split(/\t/))[JOB_END];
		
	if($jobstep =~ /^[A-Z0-9_]+$/) {
	
		$key = $jobdate .';'. $jobnumber .';'. $jobname;
		$jobstart = substr($jobstart,1);
		$jobend = substr($jobend,1);
		$step = "[$jobstep;$jobstart;$jobend] ";
		
		$jobs{$key} .= $step;
	}
	##if($jobstep !~ /^-$/) {
	#if($jobstep =~ /^[A-Z0-9]+$/) {
	#	print $step;
	#	last;
	#}
}
close $fp;

foreach(sort keys %jobs) {
	printf("%s;%s\n",$_, $jobs{$_});
}


