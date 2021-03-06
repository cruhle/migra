#TUXJES_FilterByDate.pl

#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT
#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog

#DESCRICAO DO REGISTO
use constant	SERVIDOR	=>	0;
use constant	CALLED_FROM	=>	1;
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

my @ins;
my $data_ficheiro;
my $start_time=0;
my $end_time=0;

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {
	
	chomp;
	@ins = split(/\t/);
	$data_ficheiro = (split(/\s/,$ins[DATA_HORA]))[0];	
	
	#printf("%2d %s\n",scalar @ins, $data_ficheiro);
	
	next if($data ne $data_ficheiro);
	next if(scalar @ins != 12);
		
	#print join ';', @ins,"\n";
	
	$start_time = time_2_seconds(substr($ins[START_TIME],1));
	$end_time = time_2_seconds(substr($ins[END_TIME],1));
	
	printf("%s;%s;%s;%s;%s;%s;%s;%s;%s;%04d;%s\n",
		$ins[SERVIDOR],
		$ins[CALLED_FROM],
		data_hora($ins[DATA_HORA]),
		$ins[JOB_NUMBER],
		$ins[JOB_NAME],
		$ins[STEP_NAME],
		substr($ins[START_TIME],1),
		substr($ins[END_TIME],1),
		seconds_2_time(valida_tempos($start_time, $end_time)),
		valida_tempos($start_time, $end_time),
		$ins[RETURN_CODE]
		);
			
}
close $fp;

sub data_hora {

	my $in = shift;	
	my $d = (split(/\s/,$in))[0];
	my $h = (split(/\s/,$in))[1];		
	return (
		substr($d,0,4)
		.'-'.
		substr($d,4,2)
		.'-'.
		substr($d,6,2)
		.';'.
		$h
	);
		
}

sub time_2_seconds {

	my $in = shift;	
	my $h = substr($in,0,2);
	my $m = substr($in,3,2);
	my $s = substr($in,6,2);
	return (($h*3600)+($m*60)+$s);
	
}

sub seconds_2_time {

	my $in = shift;	
	return (sprintf("%02d:%02d:%02d", $in/3600, $in/60%60, $in%60));
	
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


