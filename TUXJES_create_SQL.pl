#TUXJES_create_SQL.pl

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

use constant	DATA_HORA	=>	2;

#AREA	FO	CO	RP
my ($area, $parm) =  @ARGV; 

if($#ARGV!=1) {
	printf("\nPARAMETROS\tERRO\tERRO\tERRO\t");
	printf("Faltam parametros: area ficheiro\n");
	exit;
}

if (not defined $area) {
  die "Falta a AREA OPERACIONAL [CO|FO|RP].\n";
}

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my @ins;
my $start_time=0;
my $end_time=0;
my $work;

#tem start & end time por step
#my $SQL_INS = "INSERT INTO TBJOBS VALUES(to_date('%s','YYYYMMDD HH24:MI:SS'),'%s','%s','%s','%s','%s','%s',%d,'%s');\n";
my $SQL_INS = "INSERT INTO TBJOBS VALUES(to_date('%s','YYYYMMDD HH24:MI:SS'),'%s','%s','%s','%s',%d,'%s');\n";

my ($fichout) = cria_nome_ficheiro(uc($area));

open my $fp,'<',$parm or die "ERROR $!\n";

open my $fpo,'>', $fichout or die "ERROR $!\n";
printf($fpo "%s\n",$0);

$area = uc($area);

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@ins = split(/\t/);
		
	next if(scalar @ins != 12);
	next if($ins[STEP_NAME] eq '-');
						
	$start_time = time_2_seconds(substr($ins[START_TIME],1));
	$end_time = time_2_seconds(substr($ins[END_TIME],1));		
	$work = valida_tempos($start_time, $end_time);
		
	printf($fpo $SQL_INS,
		$ins[DATA_HORA],
		$area,
		$ins[JOB_NUMBER],
		$ins[JOB_NAME], 
		$ins[STEP_NAME],
#		substr($ins[START_TIME],1),
#		substr($ins[END_TIME],1),
		$work,
		$ins[RETURN_CODE]
	);
	
}
close $fp;
close $fpo;

printf("Fiichero [%s] criado com sucesso.\n",$fichout);

#------------------------------------------------------
#SUB-ROTINAS
#------------------------------------------------------

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

sub cria_nome_ficheiro {

	my ($area) = @_;
	
	return (sprintf("FILE_%s_SQL.log",$area)); 
	
}
