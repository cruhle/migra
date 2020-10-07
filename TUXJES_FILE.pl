#TUXJES_FILE.pl
#01513772
#01508151
#01507751
#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/01508151.bak
#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT_BCK/
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

use constant	DATA_HORA	=>	2;

#AREA	FO	CO	RP
my ($area, $parm) =  @ARGV; 

if($#ARGV!=1) {
	printf("\nPARAMETROS\tERRO\tERRO\tERRO\t");
	printf("Faltam parametros: area ficheiro\n");
	exit;
}

if (not defined $area) {
  die "Falta a AREA OPERACIONAL.\n";
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

my %dados_bi;
my %dados_acc;

my $key;
my $work;

my ($fichout, $fichsum) = cria_nome_ficheiro($area);

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@ins = split(/\t/);
	$data_ficheiro = (split(/\s/,$ins[DATA_HORA]))[0];	
		
	next if(scalar @ins != 12);
			
	$start_time = time_2_seconds(substr($ins[START_TIME],1));
	$end_time = time_2_seconds(substr($ins[END_TIME],1));
	
	$key = $ins[JOB_NAME].';'.$data_ficheiro;
	
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
		
	if(exists($dados_acc{$data_ficheiro})) {
		
		$dados_acc{$data_ficheiro}{'contador'} += 1;
		$dados_acc{$data_ficheiro}{'tempo'} += $work;
				
	} else {
		$dados_acc{$data_ficheiro} = {		
			'contador' => 1,
			'tempo' => $work
		};
	}		
}
close $fp;

my $total_execs;
my $total_tempo;

open my $fpo,'>',$fichout or die "ERROR $!\n";
printf($fpo "%s\n",$0);
printf($fpo "DATA;AREA;JOB_NAME;EXECS;TOTAL_SEGUNDOS;MEDIA_SEGUNDOS;TEMPO_MEDiO;TEMPO_TOTAL\n");
for $key (sort keys %dados_bi) {
	$total_execs += $dados_bi{$key}{'contador'};
	$total_tempo += $dados_bi{$key}{'tempo'};
	printf($fpo "%s;%s;%-8s;%05d;%05d;%06d;%s;%s\n",
		(split(/;/,$key))[1],
		$area,
		(split(/;/,$key))[0],
		$dados_bi{$key}{'contador'}, 
		$dados_bi{$key}{'tempo'},
		$dados_bi{$key}{'tempo'}/$dados_bi{$key}{'contador'},
		seconds_2_time($dados_bi{$key}{'tempo'}/$dados_bi{$key}{'contador'}),
		seconds_2_time($dados_bi{$key}{'tempo'})
	);

}

close $fpo;
printf("Ficheiro [%s] criado.\n",$fichout);

open $fpo,'>',$fichsum or die "ERROR $!\n";
printf($fpo "%s\n",$0);

printf($fpo "DATA;AREA;EXECS;TOTAL_SEGUNDOS\n");

for $key (sort keys %dados_acc) {
	printf($fpo "%s;%s;%010d;%010d\n",
		$key,
		$area,
		$dados_acc{$key}{'contador'}, 
		$dados_acc{$key}{'tempo'}
	);
}	
close $fpo;
printf("Ficheiro [%s] criado.\n",$fichsum);

#------------------------------------------------------
#SUB-ROTINAS
#------------------------------------------------------
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

sub cria_nome_ficheiro {

	my ($area) = @_;
	
	return (sprintf("FILE_%s.log",$area),sprintf("FILE_%s_sum.log",$area));
}
