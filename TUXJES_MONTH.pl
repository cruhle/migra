#TUXJES_MONTH.pl

use strict;
use warnings;

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

my @ins;
my $start_time=0;
my $end_time=0;
my $work;

#------------------------------------------------------
#DADOS DE INPUT + DATA SECTION NO FIM DO SCRIPT
#------------------------------------------------------
my $area = 'RP'; 		#FO	CO	RP
my $data = '201904';	#AAAAMM
#------------------------------------------------------
my $linha;
my $fp;
my %rc;

my ($fichout, $ficherror, $fichretcod) = cria_nome_ficheiro($area, $data);

open my $fpo,'>', $fichout or die "ERROR $!\n";
open my $fpe,'>', $ficherror or die "ERROR $!\n";
printf($fpo "%s\n",$0);
printf($fpe "%s\n",$0);

printf($fpo "DATE;TIME;AREA;JOB_NUMBER;JOB_NAME;STEP_NAME;START_TIME;END_TIME;SECONDS;RETURN_CODE\n");
printf($fpe "DATE;TIME;AREA;JOB_NUMBER;JOB_NAME;STEP_NAME;START_TIME;END_TIME;SECONDS;RETURN_CODE\n");

while(<DATA>) {

	chomp;
	$linha = $_;

	printf(".. a prooessar o ficheiro [%s]\n", $linha);
	
	open $fp,'<',$linha or die "ERROR $!\n";				
	while(<$fp>) {
		
		next if(length $_ < 20);
			
		chomp;
		@ins = split(/\t/);
			
		next if(scalar @ins != 12);
		
		next if(index($ins[2],$data) == -1 );
				
		$start_time = time_2_seconds(substr($ins[START_TIME],1));
		$end_time = time_2_seconds(substr($ins[END_TIME],1));		
		$work = valida_tempos($start_time, $end_time);
		
		printf($fpo "%s;%s;%s;%s;%s;%s;%s;%d;%s\n",
			data_hora($ins[DATA_HORA]),
			$area,
			$ins[JOB_NUMBER],
			$ins[JOB_NAME], 
			$ins[STEP_NAME],
			substr($ins[START_TIME],1),
			substr($ins[END_TIME],1),
			$work,
			$ins[RETURN_CODE]
		);
		
		if($ins[RETURN_CODE] ne 'C0000') { 
			printf($fpe "%s;%s;%s;%s;%s;%s;%s;%d;%s\n",
				data_hora($ins[DATA_HORA]),
				$area,
				$ins[JOB_NUMBER],
				$ins[JOB_NAME], 
				$ins[STEP_NAME],
				substr($ins[START_TIME],1),
				substr($ins[END_TIME],1),
				$work,
				$ins[RETURN_CODE]
			);
		}
		
		$rc{$ins[RETURN_CODE]} += 1;
	}
	close $fp;

}

close $fpo;
close $fpe;

printf("\n\nFicheiro [%s] criado com sucesso.\n",$fichout);
printf("Ficheiro erros [%s] criado com sucesso.\n",$ficherror);

open $fpo,'>',$fichretcod or die "";
printf($fpo "%s\n",$0);

printf($fpo "DATE;AREA;RETURN_CODE;QTY\n");
foreach(sort keys %rc) {
	printf($fpo "%s;%s;%s;%d\n", $data, $area, $_, $rc{$_});
}
close $fpo;
printf("Ficheiro acumulado de erros [%s] criado com sucesso.\n",$fichretcod);

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

	my ($area, $data) = @_;
	
	return (sprintf("FILE_%s_%d.log",$area, $data),
			sprintf("FILE_%s_%d_RC.log",$area, $data),
			sprintf("FILE_%s_%d_RC_SUM.log",$area, $data)
			); 
	
}


#------------------------------------------------------
#DATA
#------------------------------------------------------

__DATA__
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.033019
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.033119
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.040719
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.041419
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.042119
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.042819
