#TUXJES_R.pl

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

use lib 'lib';
require DateCalcFunctions;

my ($filtro) =  shift || '';
$filtro = uc($filtro);

if($filtro !~ /^[A-Z0-9]{5,8}$/) {
	printf("JOBNAME: 5 a 8 LETRAS e/ou NUMEROS!\n");
	printf("JOBNAME: [%s] NAO ACEITE.\nPROGRAMA A TERMINAR.\n",$filtro);
	exit;
}

#chomp(my $parm = `ls -t1 \$JESROOT/jessyslog/jessys.log.* | head -1`);

my $parm = '/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.060919';

my @registo;
my $job;
my $key;

my %lista_completa;
my $resto;
my %contador;

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {
	
	chomp;
	@registo = split(/\t/);
	next if(scalar @registo != 12);
	
	$job = $registo[JOB_NAME];
			
	next if(index($job, $filtro)<0);
	#if(index($job, $filtro)<0) {
	#	next;
	#}
	
	next if($registo[STEP_NAME] eq '-');
	
	$registo[DOMAIN] =~ s/BATCHPRD_//;
	
	$contador{$registo[JOB_NUMBER]} += 1;
	
	$key = $registo[JOB_NUMBER] .';'. $contador{$registo[JOB_NUMBER]};
		
	$resto = $registo[DOMAIN] .';';
	$resto .= (split(/\s/,$registo[DATA_HORA]))[0];
	$resto .= ';'.(split(/\s/,$registo[DATA_HORA]))[1] .';';
	$resto .= $registo[JOB_NAME] .';'.$registo[STEP_NAME].';';				
	$resto .= substr($registo[START_TIME],1) .';'.substr($registo[END_TIME],1)
	.';'.
	DateCalcFunctions::seconds_2_time(DateCalcFunctions::valida_tempos(
			DateCalcFunctions::time_2_seconds(substr($registo[START_TIME],1)),
			DateCalcFunctions::time_2_seconds(substr($registo[END_TIME],1))
		))
	.';'.$registo[RETURN_CODE];
	
	$lista_completa{$key}=$resto;
			
}
close $fp;

foreach(sort keys %lista_completa) {
	printf("%s;%s\n",$_,$lista_completa{$_});
}







