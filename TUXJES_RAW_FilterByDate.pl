#TUXJES_RAW_FilterByDate.pl

#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT
#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog

#DESCRICAO DO REGISTO
use constant	SERVIDOR	=>	0;
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
use constant	START_TIME	=>	6;
use constant	END_TIME	=>	7;
use constant	RETURN_CODE	=>	11;

use strict;
use warnings;
use integer;

use constant	DATA_HORA	=>	2;

my ($data, $parm) =  @ARGV; # || die "Usage: $0 YYYYMMDD FICHEIRO\n";

if (not defined $data) {
  die "Falta a data no formato YYYYMMDD para filtrar.\n";
}

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my @record;
my $data_ficheiro;
my $start_time;
my $end_time;
my $domain;
my ($start_seconds, $end_seconds, $seconds) = (0,0,0);

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {
	
	next if(length $_ < 20);
	
	next if(/AUTOPURGED	ARTJESADM|SUBMITTED	ARTJESADM|STARTED|ENDED/);	
	
	chomp;
	
	@record = split(/\t/);
	$data_ficheiro = (split(/\s/,$record[DATA_HORA]))[0];		
	
	next if($data ne $data_ficheiro);
	
	#print substr($record[6],1),"\t",substr($record[7],1),"\n";
	$start_time = substr($record[6],1);
	$end_time = substr($record[7],1);
	
	$start_seconds = time_2_seconds($start_time);
	$end_seconds = time_2_seconds($end_time);
	$seconds = $end_seconds-$start_seconds;
	$seconds = valida_tempos($start_seconds, $end_seconds);
	
	$domain = $record[DOMAIN];
	$domain =~ m/\_([A-Z]{2}$)/;
	$domain =  $1;
			
	#print "$start_time\t$end_time\t$start_seconds\t$end_seconds\t$seconds\n" if($start_time ne $end_time);
	#print "$start_time $end_time $start_seconds\t$end_seconds\t$seconds\n" if($seconds>59);
	printf("%s %s %s %s %s %6d %6d %6d %s\n",
			$data_ficheiro,
			$record[JOB_NUMBER],
			$domain,
			$start_time,
			$end_time,
			$start_seconds,
			$end_seconds,
			$seconds,
			seconds_2_time($seconds)
	) if($seconds>120);
	
	#print "$_\n";					
}
close $fp;

#-----------ROTINAS-------------
sub time_2_seconds {
	my $in = shift;	
	my $h = substr($in,0,2);
	my $m = substr($in,3,2);
	my $s = substr($in,6,2);
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

sub seconds_2_time {
	my $in = shift;	
	
	return (sprintf("%02d:%02d:%02d", $in/3600, $in/60%60, $in%60));	
}