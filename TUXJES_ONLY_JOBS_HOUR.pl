#TUXJES_ONLY_JOBS_STEPS.pl

#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog
#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT

#DESCRICAO DO REGISTO

use constant	JOB_DOMAIN	=>	1;
use constant	JOB_DATE	=>	2;
use constant	JOB_NUMBER	=>	3;
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

my $jobdomain;
my $jobdate;
my $jobhour;
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
	#next if($jobstep !~ /^START$/);
	
	$jobdate  = (split(/\s/,(split(/\t/))[JOB_DATE]))[0];
	$jobhour  = substr((split(/\s/,(split(/\t/))[JOB_DATE]))[1],0,2);		
	
	$jobdomain = (split(/\t/))[JOB_DOMAIN];
	$jobdomain =~ s/BATCHPRD_//g;
	
	$key = $jobdate .';'. $jobhour;
			
	$jobstart = (split(/\t/))[JOB_START];
	$jobend = (split(/\t/))[JOB_END];
		
	$jobstart = time_2_seconds(substr($jobstart,1));
	$jobend = time_2_seconds(substr($jobend,1));
	$step = valida_tempos($jobstart, $jobend);			
	
	if(exists($jobs{$key})) {
		$jobs{$key}{'jobs'}+=1 if ($jobstep eq 'START');
		$jobs{$key}{'time'}+=$step;
	} else {
		$jobs{$key} = {
			'jobs' => 1,
			'time' => $step
		};
	}
	
	
	
}
close $fp;

foreach(sort keys %jobs) {
	printf("%s;%s;%d;%d\n",
		$jobdomain,
		$_, 
		$jobs{$_}{'jobs'},
		$jobs{$_}{'time'}
	);
}

#-------------ROTINAS
sub time_2_seconds {
	my $in = shift;
	my ($h, $m, $s) = split(/:/,$in);			
	return (($h*3600)+($m*60)+$s);	
}

sub valida_tempos {
	my ($t1, $t2) = @_;
	my $rv = 0;	
	if($t1 > $t2) {
		$rv = (86400-$t1) + $t2;
	} else {
		$rv = $t2 - $t1;
	}	
	return $rv;
}
