#cat delays_fO_061619.csv | grep - > delays_fO_N_061619.csv

#TUXJES_DELAY.pl

use strict;
use warnings;
use Time::Piece;
use File::Basename;

use lib 'lib';
require DateCalcFunctions;

my $ficheiro = shift || die "ERROR - FILE TO READ?\n";

if(!-e $ficheiro) {
	die "File [$ficheiro] not found.\n";
}

my $filename = basename($ficheiro);
$filename =~ /(\d+)/;
$filename = '/tmp/pkis/delays_XX_'. $1 .'.csv';

#RECORD LAYOUT FOR THIS SCRIPT
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	OPER		=>	6;
use constant	RETURN_CODE	=>	7;

my @registo;
my %delays;
my %tempos;
my $key;
my $domain;

my ($data, $hora, $job_nbr, $job_nm, $oper) = ('', '', '', '', '');
my $retcode;

#dione	BATCHPRD_RP	20190626 11:12:32	01196617	ARSB2S	-	SUBMITTED	ARTJESADM	1_1	15794284
#dione	BATCHPRD_RP	20190626 11:12:34	01196617	ARSB2S	-	STARTED	-	CLASS	A	SYS	dione	1_30	11208184	START
#dione	BATCHPRD_RP	20190623 00:10:28	01191249	PTARACR2	-	ENDED	C0000

open my $fp,'<',$ficheiro or die "ERROR $!\n";
while(<$fp>) {

	if(/SUBMITTED/) {
		chomp;
		@registo = split(/\t/);
		$key = @registo;
		next if($key!=10);
		
		separa_campos_registo();
		$key = $job_nbr;
		$domain = $registo[DOMAIN];
		
		if(exists($delays{$key})) {		
			$delays{$key} = {		
				'data_subm' => $data,
				'hora_subm' => $hora,
				'domain' => $registo[DOMAIN],
				'job' => $job_nm,
				'oper_subm' => $oper,
				'data_start' => $delays{$key}{'data_start'},
				'hora_start' => $delays{$key}{'hora_start'},
				'oper_start' => $delays{$key}{'oper_start'},
				'data_end' => $delays{$key}{'data_end'},
				'hora_end' => $delays{$key}{'hora_end'},
				'oper_end' => $delays{$key}{'oper_end'},
				'ret_code' => $delays{$key}{'ret_code'}
			};
			
		} else {
			$delays{$key} = {		
				'data_subm' => $data,
				'hora_subm' => $hora,
				'domain' => $registo[DOMAIN],
				'job' => $job_nm,
				'oper_subm' => $oper,
				'data_start' => '',
				'hora_start' => '',
				'oper_start' => '',
				'data_end' => '',
				'hora_end' => '',
				'oper_end' => '',
				'ret_code' => ''
			};
		}
		
		next:
	}
	
	if(/STARTED/) {
		chomp;
		@registo = split(/\t/);
		$key = @registo;
		#next if($key!=15);		
		
		separa_campos_registo();
		$key = $job_nbr;
		next if($oper ne 'STARTED');
	
		if(exists($delays{$key})) {
			$delays{$key} = {	
				'data_subm' => $delays{$key}{'data_subm'},
				'hora_subm' => $delays{$key}{'hora_subm'},
				'domain' => $delays{$key}{'domain'},
				'job' => $delays{$key}{'job'},
				'oper_subm' => $delays{$key}{'oper_subm'},
				'data_start' => $data,
				'hora_start' => $hora,
				'oper_start' => $oper,
				'data_end' => '',
				'hora_end' => '',
				'oper_end' => '',
				'ret_code' => ''
			};
		} else {
			$delays{$key} = {		
				'data_subm' => '',
				'hora_subm' => '',
				'oper_subm' => '',
				'domain' => $registo[DOMAIN],
				'job' => $job_nm,
				'data_start' => $data,
				'hora_start' => $hora,
				'oper_start' => $oper,
				'data_end' => '',
				'hora_end' => '',
				'oper_end' => '',
				'ret_code' => ''
			};
		}
		next;
	}
	
	if(/ENDED/) {
		chomp;
		@registo = split(/\t/);
		$key = @registo;
		next if($key!=8);
		
		separa_campos_registo();
		$key = $job_nbr;
				
		$delays{$key} = {	
			'data_subm' 	=> $delays{$key}{'data_subm'},
			'hora_subm' 	=> $delays{$key}{'hora_subm'},
			'domain' 		=> $delays{$key}{'domain'},
			'job' 			=> $delays{$key}{'job'},
			'oper_subm' 	=> $delays{$key}{'oper_subm'},
			'data_start' 	=> $delays{$key}{'data_start'},
			'hora_start' 	=> $delays{$key}{'hora_start'},
			'oper_start' 	=> $delays{$key}{'oper_start'},
			'data_end' 		=> $data,
			'hora_end' 		=> $hora,
			'oper_end' 		=> $oper,
			'ret_code' 		=> $retcode
		};		
		
	}
	
}
close $fp;

#JOB_NUMBER;
#JOB_NAME;
#DOMAIN;
#SUBMITTED;
#SUBM_DATE;
#SUBM_TIME;
#STARTED;
#START_DATE;
#START_TIME;
#ENDED;
#END_DATE;
#END_TIME;
#START_SUBMITTED;
#ENDED_STARTED;
#RETURN_CODE

$filename =~ s/XX/$domain/g;


#printf("JOB_NUMBER;JOB_NAME;DOMAIN;SUBMITTED;SUBM_DATE;SUBM_TIME;STARTED;START_DATE;START_TIME;ENDED;END_DATE;END_TIME;START_SUB_SEC;START_SUB_DUR;END_START_SEC;END_START_DUR;RETURN_CODE\n");

open $fp,'>',$filename;
printf($fp "%s\n",$0);

printf($fp "JOB_NUMBER;JOB_NAME;DOMAIN;SUB_DATE;SUB_TIME;START_DATE;START_TIME;END_DATE;END_TIME;START_MINUS_SUB_SEC;END_MINUS_START_SEC;RETURN_CODE\n");
foreach(sort keys %delays) {
	#printf("%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s",
		printf($fp "%s;%s;%s;%s;%s;%s;%s;%s;%s",
		$_, 
		$delays{$_}{'job'},
		$delays{$_}{'domain'},
		#$delays{$_}{'oper_subm'},
		$delays{$_}{'data_subm'},
		$delays{$_}{'hora_subm'},
		#$delays{$_}{'oper_start'},
		$delays{$_}{'data_start'},
		$delays{$_}{'hora_start'},		
		#$delays{$_}{'oper_end'},
		$delays{$_}{'data_end'},
		$delays{$_}{'hora_end'}		
	);
	
	if(($delays{$_}{'data_subm'}) ne '' 
		and ($delays{$_}{'hora_subm'} ne '')
		and ($delays{$_}{'data_start'} ne '')
		and ($delays{$_}{'hora_start'} ne '')) {
		
		$data = $delays{$_}{'data_subm'} .' '. $delays{$_}{'hora_subm'};
		$hora = $delays{$_}{'data_start'} .' '. $delays{$_}{'hora_start'};
		$oper = get_total_work_time($data, $hora);				
		#cache_tempos($oper);
		#printf(";%d;%s",$oper,DateCalcFunctions::seconds_2_time($oper));		
		printf($fp ";%d",$oper);		
	} else { printf($fp ";"); }
	
	if(($delays{$_}{'data_start'}) ne '' 
		and ($delays{$_}{'hora_start'} ne '')
		and ($delays{$_}{'data_end'} ne '')
		and ($delays{$_}{'hora_end'} ne '')) {
		
		$data = $delays{$_}{'data_start'} .' '. $delays{$_}{'hora_start'};
		$hora = $delays{$_}{'data_end'} .' '. $delays{$_}{'hora_end'};
		$oper = get_total_work_time($data, $hora);				
		#cache_tempos($oper);
		#printf(";%d;%s",$oper,DateCalcFunctions::seconds_2_time($oper));		
		printf($fp ";%d",$oper);		
	} else { printf($fp ";"); }
	
	printf($fp ";%s\n",$delays{$_}{'ret_code'});
	
}
close $fp;

printf("Ficheiro [%s] criado.\n",$filename);

#-------TEMPOS CACHE---------------
#$data=0;
#$hora=0;
#foreach(sort keys %tempos) {
#	printf("%6d %s %d\n",$_, $tempos{$_}{'duracao'},$tempos{$_}{'qtd'});
#	$data++;
#	$hora+=$tempos{$_}{'qtd'};
#}
#printf("\n%d %d\n",$data,$hora);
#---------------ROTINAS------------
sub separa_campos_registo {

	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	$data = (split(/\s/,$registo[DATA_HORA]))[0];
	$hora = (split(/\s/,$registo[DATA_HORA]))[1];
	$job_nbr = $registo[JOB_NUMBER];
	$job_nm = $registo[JOB_NAME];
	$oper = $registo[OPER];
	$retcode = $registo[RETURN_CODE];
}

sub get_total_work_time {

	my ($t_start, $t_end) = @_;
	
	my $t_s = Time::Piece->strptime($t_start,"%Y%m%d %H:%M:%S");
	my $t_e = Time::Piece->strptime($t_end,"%Y%m%d %H:%M:%S");
	
	return ($t_e->epoch - $t_s->epoch);
	
	#if($t_e->epoch > $t_s->epoch) {
	#	return ($t_e->epoch - $t_s->epoch);
	#} else {
	#	return ($t_s->epoch - $t_e->epoch);
	#}
}

sub cache_tempos {

	my $tmp = shift;

	if(exists($tempos{$tmp})) {
		$tempos{$tmp}{'qtd'} +=1;
	} else {
		$tempos{$tmp} = {
			'duracao' => DateCalcFunctions::seconds_2_time(abs($tmp)),
			'qtd' => 1
			
		};
	}


}