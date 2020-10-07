#TUXJES_JOB_HISTORY_V_II.pl

#	OPER		ARRAY SIZE
#   ----------- ----------
#	SUBMITTED	10
#	STARTED		15
#	ENDED		8


use strict;
use warnings;
use File::Basename;
use Time::Piece;

use lib 'lib';
require WorktimeFunction;

#DESCRICAO DO REGISTO
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	OPERATION	=>	6;
use constant	RETURN_CODE	=>	7;

my ($parm) =  @ARGV; 

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my ($size, @registo, %tabela ) = ('', (), 0, ());
my ($data, $job_nbr, $job_nm, $domain, $tmp) = ('', '', '', '', '');

my $filename = basename($parm);
$filename =~ /(\d+)/;
$filename = '/tmp/pkis/jobs_history_XX_'. $1 .'.csv';

open my $fp,'<',$parm or die "ERROR $!\n";
while(<$fp>) {

	next if(!/(\tSUBMITTED\t|\tSTARTED\t|\tENDED\t)/);
	
	chomp;
	@registo 			= split(/\t/);
	$size 				= @registo;
	
	$job_nbr 			= $registo[JOB_NUMBER];
	$job_nm 			= $registo[JOB_NAME];
	$registo[DOMAIN] 	=~ s/BATCHPRD_//;
	$domain 			= $registo[DOMAIN];
	$data	 			= $registo[DATA_HORA];
	

	#SUBMITTED-START	
	if(/(\tSUBMITTED\t)/) {
	
		next if($size!=10 or $registo[OPERATION] ne 'SUBMITTED');
		
		$tabela{$job_nbr}{'domain'}		 		= 	$domain;
		$tabela{$job_nbr}{'data_submitted'}		=	$data;
		$tabela{$job_nbr}{'job_name'}			=	$job_nm;			
			
		next;
	}
	#SUBMITTED-END	

	#STARTED-START	
	if(/(\tSTARTED\t)/) {
	
		next if($size!=15 or $registo[OPERATION] ne 'STARTED');
	
		$tabela{$job_nbr}{'domain'}		 		= 	$domain;
		$tabela{$job_nbr}{'data_started'}		=	$data;
		$tabela{$job_nbr}{'job_name'}			=	$job_nm;			
					
		next;
	}
	#STARTED-END
		
	#ENDED-START	
	if(/(\tENDED\t)/) {
			
		next if($size!=8 or $registo[OPERATION] ne 'ENDED');
		
		$tabela{$job_nbr}{'domain'}		 		= 	$domain;
		$tabela{$job_nbr}{'data_ended'}			=	$data;
		$tabela{$job_nbr}{'job_name'}			=	$job_nm;			
		$tabela{$job_nbr}{'return_code'}		=	$registo[RETURN_CODE];			
		
		next;
	}
	#ENDED-END	
	
}
close $fp;
$filename =~ s/XX/$domain/g;

open $fp,'>',$filename;
printf($fp "%s\n",$0);

printf($fp "JOB_NUMBER;DOMAIN;JOB_NAME;DATA_SUBMITTED;DATA_STARTED;SECONDS_TO_START;DATA_ENDED;RUNTIME_SECONDS;RETURN_CODE\n");
foreach(sort keys %tabela) {

	printf($fp "%s;%s;%s",
		$_,
		$tabela{$_}{'domain'},
		$tabela{$_}{'job_name'},		
	);
	
	$tmp = '';
	if(exists($tabela{$_}{'data_submitted'})) {
		$tmp = $tabela{$_}{'data_submitted'};
	} 
	printf($fp ";%s",$tmp);
	
	$tmp = '';
	if(exists($tabela{$_}{'data_started'})) {
		$tmp = $tabela{$_}{'data_started'};
	} 
	printf($fp ";%s",$tmp);
	
	$tmp = 0;
	if(exists($tabela{$_}{'data_submitted'}) and exists($tabela{$_}{'data_started'}))  {
		$tmp = WorktimeFunction::getWorkTimeInSeconds(
			$tabela{$_}{'data_submitted'},
			$tabela{$_}{'data_started'});			
	} 
	printf($fp ";%d",$tmp);
	
	$tmp = '';
	if(exists($tabela{$_}{'data_ended'})) {
		$tmp = $tabela{$_}{'data_ended'};
	} 
	printf($fp ";%s",$tmp);
	
	$tmp = 0;
	if(exists($tabela{$_}{'data_started'}) and exists($tabela{$_}{'data_ended'}))  {
		$tmp = WorktimeFunction::getWorkTimeInSeconds(
			$tabela{$_}{'data_started'},
			$tabela{$_}{'data_ended'});			
	} 
	printf($fp ";%d",$tmp);
	
	$tmp = '';
	if(exists($tabela{$_}{'return_code'})) {
		$tmp = $tabela{$_}{'return_code'};
	} 
	printf($fp ";%s\n",$tmp);
	
}
close $fp;

printf("Ficheiro [%s] criado.\n",$filename);

