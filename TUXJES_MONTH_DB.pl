#TUXJES_MONTH_DB.pl

use strict;
use warnings;

#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog
#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT
#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/01675751.bak
#PRD/RUNTIME/PROD/CO/batch
#------------------------------------------------------

# no start or end_job !

#------------------------------------------------------

#DESCRICAO DO REGISTO
use constant	SERVIDOR		=>	0;
use constant	CALLED_FROM		=>	1;
use constant	DATA_HORA		=>	2;
use constant	JOB_NUMBER		=>	3;
use constant	JOB_NAME		=>	4;
use constant	STEP_NAME		=>	5;
use constant	START_TIME		=>	6;
use constant	END_TIME		=>	7;
use constant	RETURN_CODE		=>	11;

my @ins;
my $start_time=0;
my $end_time=0;
my $work;

#------------------------------------------------------
#DADOS DE INPUT + DATA SECTION NO FIM DO SCRIPT
#NO FIM DO SCRIPT A LISTA DOS FICHEIROS A SEREM PROCESSADOS
#------------------------------------------------------

my $area = 'FO'; 		#	FO	CO	RP
my $data = '201905';	#	AAAAMM

#------------------------------------------------------

my $linha;
my $fp;
my %rc;

my ($fichout) = cria_nome_ficheiro($area, $data);

open my $fpo,'>', $fichout or die "ERROR $!\n";
printf($fpo "%s\n",$0);

while(<DATA>) {

	chomp;
	$linha = $_;

	printf("A processar ... [%s] ...\n", $linha);
	
	open $fp,'<',$linha or die "ERROR $!\n";				
	while(<$fp>) {
		
		next if(length $_ < 20);
			
		chomp;
		@ins = split(/\t/);
			
		next if(scalar @ins != 12);
		
		next if(index($ins[2],$data) == -1 );
		
		#next if($ins[STEP_NAME] eq 'START' or $ins[STEP_NAME] eq 'END_JOB');
				
		$start_time = time_2_seconds(substr($ins[START_TIME],1));
		$end_time = time_2_seconds(substr($ins[END_TIME],1));		
		$work = valida_tempos($start_time, $end_time);
		
		printf($fpo "INSERT INTO TBJOBS VALUES ('%s','%s','%s','%s',%d,'%s');\n",
			data_oracle($ins[DATA_HORA]),
			$ins[JOB_NUMBER],
			$ins[JOB_NAME], 
			$ins[STEP_NAME],
			$work,
			$ins[RETURN_CODE]
		);
		
	}
	
	close $fp;

}

close $fpo;

printf("\n\nFicheiro [%s] criado com sucesso.\n",$fichout);


#------------------------------------------------------
#SUB-ROTINAS
#------------------------------------------------------

sub data_oracle {

	my $in = shift;	
	
	return sprintf("TO_DATE('%s','YYYYMMDD HH24:MI:SS')",$in);
		
}

sub data {

	my $in = shift;	
	my $d = (split(/\s/,$in))[0];
	my $h = (split(/\s/,$in))[1];		
	return (
		substr($d,0,4)
		.'-'.
		substr($d,4,2)
		.'-'.
		substr($d,6,2)
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
	
	return (sprintf("FILE_%s_%d.SQL",$area, $data)); 
	
}


#------------------------------------------------------
#DATA
#------------------------------------------------------

__DATA__
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.033119
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.040719
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.041419
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.042119
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.042819
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.050519