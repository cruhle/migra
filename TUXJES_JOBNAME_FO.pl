#TUXJES_JOBNAME.pl

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

use constant	ALL_STEPS	=>	1;		
# se == 1 soh imprime se steps == 19 || 21 || 22 !

use strict;
use warnings;
#use integer;

use constant	DATA_HORA	=>	2;

my ($parm) =  @ARGV; # or die "Usage: $0 FICHEIRO\n";

if($#ARGV!=0) {
	printf("\nPARAMETROS\tERRO\tERRO\tERRO\t");
	printf("Faltam parametros: ficheiro\n");
	exit;
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

my %dados_jobname;
my $key;
my $work;
my $data;

my ($fichout) = cria_nome_ficheiro();

open my $fp,'<',$parm or die "ERROR $!\n";

open my $fpo,'>',$fichout or die "ERROR $!\n";
printf($fpo "%s\n",$0);

while(<$fp>) {

	next if(length $_ < 20);
	
	#unless(/.+[PTTMBCSI|PTATTTRF]\sLATMB.+/) {
	unless(/.+(PTTMBCSI|PTATTTRF)\s[A-Z0-9]+.+/) {
		next;
	}
	
	chomp;
	@ins = split(/\t/);
	next if(scalar @ins != 12);
		
	$start_time = time_2_seconds(substr($ins[START_TIME],1));
	$end_time = time_2_seconds(substr($ins[END_TIME],1));
	
	$data = (split(/\s/,$ins[DATA_HORA]))[0];
	
	$key = $data .';'. $ins[JOB_NUMBER] .';'. $ins[JOB_NAME];
	
	$work = valida_tempos($start_time, $end_time);
	
	if(exists($dados_jobname{$key})) {		
		$dados_jobname{$key}{'steps'} += 1;
		$dados_jobname{$key}{'tempo'} += $work;
				
	} else {
		$dados_jobname{$key} = {		
			'steps' => 1,
			'tempo' => $work
		};
	}
		
}
close $fp;

printf($fpo "DATE;JOB_NUMBER;JOB_NAME;STEPS;SECONDS;DURATION\n");
for $key (sort keys %dados_jobname) {
	printf($fpo "%s;%02d;%05d;%s\n",
		$key,
		$dados_jobname{$key}{'steps'}, 
		$dados_jobname{$key}{'tempo'},
		seconds_2_time($dados_jobname{$key}{'tempo'})
	);
#	) if ($dados_jobname{$key}{'steps'}==19);	# soh os que correram os 19 steps!
#	) if (!ALL_STEPS or (ALL_STEPS and $dados_jobname{$key}{'steps'}==19));	# soh os que correram os 19 steps!
#	) if (!ALL_STEPS or (ALL_STEPS and 
#			($dados_jobname{$key}{'steps'}==21) or 
#			($dados_jobname{$key}{'steps'}==22))
#		  );	

}

close $fpo;
printf("Ficheiro [%s] criado.\n",$fichout);

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
	
	return (sprintf("BY_JOB_NAME_FO.log"));
}
