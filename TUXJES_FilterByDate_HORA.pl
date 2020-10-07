#TUXJES_FilterByDate_HORA.pl

#filtra so por uma data

#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog
#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT

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
#use integer;

my ($area, $data, $parm) =  @ARGV; # || die "Usage: $0 AREA YYYYMMDD FICHEIRO\n";

if (not defined $area) {
  die "Falta a area.\n";
}

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
my $hora;
my $start_time=0;
my $end_time=0;

my %dados_bi;
my $key;
my $work;

my $fileout = uc($area).'_'.$data.'.csv';

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@ins = split(/\t/);
	$data_ficheiro = (split(/\s/,$ins[DATA_HORA]))[0];	
	$hora = (split(/\s/,$ins[DATA_HORA]))[1];
	$hora = substr($hora,0,2);	
	
	next if($data ne $data_ficheiro);
	next if(scalar @ins != 12);
	
	$start_time = time_2_seconds(substr($ins[START_TIME],1));
	$end_time = time_2_seconds(substr($ins[END_TIME],1));
	
	$key = $hora;
	$work = valida_tempos($start_time, $end_time);
	
	if(exists($dados_bi{$key})) {
		
		$dados_bi{$key}{'contador'} += 1;
		$dados_bi{$key}{'tempo'} += $work;
				
	} else {
		$dados_bi{$key} = {		
			'contador' => 1,
			'tempo' => $work
		};
	}
		
}
close $fp;

open $fp,'>',$fileout or die "ERROR $!n";
printf($fp "%s\n",$0);

printf($fp "AREA;DATA;HORA;EXECS;TOTAL_SEGUNDOS\n");

for $key (sort keys %dados_bi) {
	printf($fp "%s;%s;%02d;%d;%d\n",
		uc($area),
		$data,
		$key,
		$dados_bi{$key}{'contador'}, 
		$dados_bi{$key}{'tempo'}		
	);

}

close $fp;

printf("Ficheiro [$fileout] criado com sucesso.\n");

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


