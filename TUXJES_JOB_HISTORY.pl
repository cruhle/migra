#TUXJES_JOB_HISTORY.pl

#	OPER		ARRAY SIZE
#	SUBMITTED	12
#	STARTED		15
#	END_JOB		12
#	ENDED		8
#	AUTOPURGED	10

use strict;
use warnings;
use File::Basename;

#use lib 'lib';
#require DateCalcFunctions;

#DESCRICAO DO REGISTO
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
use constant	START_TIME	=>	6;
use constant	END_TIME	=>	7;
use constant	RETURN_CODE	=>	11;

my ($parm) =  @ARGV; 

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my ($size, @registo, $cnt, %tabela ) = ('', (), 0, ());
my ($data_job, $hora_job, $job_nbr, $job_nm, $domain, $key) = ('', '', '', '', '', '');

my $filename = basename($parm);
$filename =~ /(\d+)/;
$filename = '/tmp/pkis/jobs_history_XX_'. $1 .'.csv';

open my $fp,'<',$parm or die "ERROR $!\n";
while(<$fp>) {

	chomp;
	@registo 			= split(/\t/);
	$size 				= @registo;
	
	$key 				= $registo[JOB_NUMBER];
	
	$job_nbr 			= $registo[JOB_NUMBER];
	$job_nm 			= $registo[JOB_NAME];
	$registo[DOMAIN] 	=~ s/BATCHPRD_//;
	$domain 			= $registo[DOMAIN];
	$data_job 			= (split(/\s/,$registo[DATA_HORA]))[0];
	$hora_job 			= (split(/\s/,$registo[DATA_HORA]))[1];
	

	#SUBMITTED-START	
	if(/(\tSUBMITTED\t)/) {
	
		next if($size!=10);
	
		if(exists($tabela{$key})) {
			#verifica_conteudo_campos();
			$tabela{$key}{'data_log'}			=	$data_job .' '. $hora_job;
			$tabela{$key}{'data_submitted'}		=	$data_job .' '. $hora_job;
			$tabela{$key}{'job_name'}			=	$job_nm;			
			$tabela{$key}{'domain'}				=	$domain;
		} else {
			$tabela{$key} = {
				'data_log'						=>	$data_job .' '. $hora_job,
				'data_submitted' 				=>	$data_job .' '. $hora_job,
				'job_name' 						=>	$job_nm,
				'domain' 						=>	$domain,
				'data_started' 					=>	'',
				'data_start' 					=>	'',
				'data_end_job'					=>	'',
				'data_ended' 					=>	'',
				'data_purge' 					=>	'',
				'return_code' 					=>	''
			};
		}	
		next;
	}
	#SUBMITTED-END	

	#STARTED-START	
	if(/(\tSTARTED\t)/) {
	
		next if($size!=15);
	
		if(exists($tabela{$key})) {
			#verifica_conteudo_campos();
			$tabela{$key}{'data_started'}		=	$data_job .' '. $hora_job;			
			$tabela{$key}{'job_name'}			=	$job_nm;			
			$tabela{$key}{'domain'}				=	$domain;
		} else {
			$tabela{$key} = {
				'data_log'						=>	'',
				'data_submitted' 				=>	'',
				'job_name' 						=>	$job_nm,
				'domain' 						=>	$domain,
				'data_started' 					=>	$data_job .' '. $hora_job,
				'data_start' 					=>	'',
				'data_end_job'					=>	'',
				'data_ended' 					=>	'',
				'data_purge' 					=>	'',
				'return_code' 					=>	''
			};
		}	
		next;
	}
	#STARTED-END
	
	#START-START	
	if(/(\tSTART\t)/) {
	
		next if($size!=12);
	
		if(exists($tabela{$key})) {
			#verifica_conteudo_campos();
			$tabela{$key}{'data_start'}		=	$data_job .' '. $hora_job;			
		} else {
			$tabela{$key} = {
				'data_log'						=>	'',
				'data_submitted' 				=>	'',
				'job_name' 						=>	'',
				'domain' 						=>	'',
				'data_started' 					=>	'',
				'data_start' 					=>	$data_job .' '. $hora_job,
				'data_end_job'					=>	'',
				'data_ended' 					=>	'',
				'data_purge' 					=>	'',
				'return_code' 					=>	''
			};
		}	
		next;
	}
	#START-END	

	#END_JOB-START	
	if(/(\tEND_JOB\t)/) {
		
		next if($size!=12);
		
		if(exists($tabela{$key})) {
			#verifica_conteudo_campos();
			$tabela{$key}{'data_end_job'}		=	$data_job .' '. $hora_job;			
		} else {
			$tabela{$key} = {
				'data_log'						=>	'',
				'data_submitted' 				=>	'',
				'job_name' 						=>	'',
				'domain' 						=>	'',
				'data_started' 					=>	'',
				'data_start' 					=>	'',
				'data_end_job'					=>	$data_job .' '. $hora_job,
				'data_ended' 					=>	'',
				'data_purge' 					=>	'',
				'return_code' 					=>	''
			};
		}	
		next;
	}
	#END_JOB-END		

	#ENDED-START	
	if(/(\tENDED\t)/) {
			
		next if($size!=8);
		
		if(exists($tabela{$key})) {
			#verifica_conteudo_campos();
			$tabela{$key}{'data_ended'}			=	$data_job .' '. $hora_job;
			$tabela{$key}{'return_code'}		=	$registo[END_TIME];
		} else {
			$tabela{$key} = {
				'data_log'						=>	'',
				'data_submitted' 				=>	'',
				'job_name' 						=>	'',
				'domain' 						=>	'',
				'data_started' 					=>	'',
				'data_start' 					=>	'',
				'data_end_job'					=>	'',
				'data_ended' 					=>	$data_job .' '. $hora_job,
				'data_purge' 					=>	'',
				'return_code' 					=>	$registo[END_TIME]			#pos 7 neste caso
			};
		}	
		next;
	}
	#ENDED-END	
	
	#AUTOPURGED-START	
	if(/(\tAUTOPURGED\t)/) {

		next if($size!=10);
		
		if(exists($tabela{$key})) {
			#verifica_conteudo_campos();
			$tabela{$key}{'data_purge'}			=	$data_job .' '. $hora_job;
		} else {
			$tabela{$key} = {
				'data_log'						=>	'',
				'data_submitted' 				=>	'',
				'job_name' 						=>	'',
				'domain' 						=>	'',
				'data_started' 					=>	'',
				'data_start' 					=>	'',
				'data_end_job'					=>	'',
				'data_ended' 					=>	'',
				'data_purge'					=>	$data_job .' '. $hora_job,
				'return_code' 					=>	''
			};
		}	
		next;
	}
	#AUTOPURGED-END		

}
close $fp;
$filename =~ s/XX/$domain/g;

open $fp,'>',$filename;
printf($fp "%s\n",$0);

printf($fp "JOB_NUMBER;DATA_LOG;DATA_SUBMITTED;JOB_NAME;DOMAIN;DATA_STARTED;DATA_START;END_JOB;ENDED;DATA_PURGE;RETURN_CODE\n");
foreach(sort keys %tabela) {

	#next if(index($tabela{$_}{'data_log'},'20190628')==-1);	
	
	printf($fp "%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n",
		$_,
		$tabela{$_}{'data_log'},
		$tabela{$_}{'data_submitted'},
		$tabela{$_}{'job_name'},
		$tabela{$_}{'domain'},
		$tabela{$_}{'data_started'},
		$tabela{$_}{'data_start'},
		$tabela{$_}{'data_end_job'},
		$tabela{$_}{'data_ended'},
		$tabela{$_}{'data_purge'},
		$tabela{$_}{'return_code'}
	);
}
close $fp;

printf("Ficheiro [%s] criado.\n",$filename);

#------------ROTINAS

sub verifica_conteudo_campos {

	$tabela{$key}{'data_log'} 			= ($tabela{$key}{'data_log'} ne '' ? $tabela{$key}{'data_log'}:'');
	$tabela{$key}{'data_submitted'} 	= ($tabela{$key}{'data_submitted'} ne '' ? $tabela{$key}{'data_submitted'}:'');
	$tabela{$key}{'job_name'} 			= ($tabela{$key}{'job_name'} ne '' ? $tabela{$key}{'job_name'}:'');
	$tabela{$key}{'domain'} 			= ($tabela{$key}{'domain'} ne '' ? $tabela{$key}{'domain'}:'');
	$tabela{$key}{'data_started'} 		= ($tabela{$key}{'data_started'} ne '' ? $tabela{$key}{'data_started'}:'');
	$tabela{$key}{'data_start'} 		= ($tabela{$key}{'data_start'} ne '' ? $tabela{$key}{'data_start'}:'');
	$tabela{$key}{'data_end_job'} 		= ($tabela{$key}{'data_end_job'} ne '' ? $tabela{$key}{'data_end_job'}:'');
	$tabela{$key}{'data_ended'} 		= ($tabela{$key}{'data_ended'} ne '' ? $tabela{$key}{'data_ended'}:'');
	$tabela{$key}{'data_purge'} 		= ($tabela{$key}{'data_purge'} ne '' ? $tabela{$key}{'data_purge'}:'');
	$tabela{$key}{'return_code'} 		= ($tabela{$key}{'return_code'} ne '' ? $tabela{$key}{'return_code'}:'');
	
}

#__DATA__
#dione	BATCHPRD_RP	20190625 16:00:14	01195329	PTARARAF	-	SUBMITTED	ARTJESADM	1_1	15794284
#dione	BATCHPRD_RP	20190625 16:00:19	01195329	PTARARAF	-	STARTED	-	CLASS	P	SYS	dione	1_45	50593974	START
#dione	BATCHPRD_RP	20190625 16:00:19	01195329	PTARARAF	START	S16:00:19	E16:00:19	-	-	-	C0000
#dione	BATCHPRD_RP	20190625 16:01:44	01195329	PTARARAF	CONCATENAR_FICHEIROS	S16:00:20	E16:01:44	-	-	-	C0000
#dione	BATCHPRD_RP	20190625 17:00:56	01195329	PTARARAF	LRPLOYF2	S16:01:44	E17:00:56	-	-	-	C0000
#dione	BATCHPRD_RP	20190625 17:00:57	01195329	PTARARAF	ZIPFICH_LRPLOYF2	S17:00:56	E17:00:57	-	-	-	C0000
#dione	BATCHPRD_RP	20190625 17:00:57	01195329	PTARARAF	EMAIL_LRPLOYF2	S17:00:57	E17:00:57	-	-	-	C0000
#dione	BATCHPRD_RP	20190625 17:00:59	01195329	PTARARAF	REMOVER_FICHEIROS	S17:00:58	E17:00:59	-	-	-	C0000
#dione	BATCHPRD_RP	20190625 20:44:59	01195329	PTARARAF	LRPAPX23	S17:01:00	E20:44:59	-	-	-	C0000
#dione	BATCHPRD_RP	20190625 20:45:00	01195329	PTARARAF	ZIP	S20:45:00	E20:45:00	-	-	-	C0000
#dione	BATCHPRD_RP	20190625 20:45:01	01195329	PTARARAF	MAIL	S20:45:01	E20:45:01	-	-	-	C0000
#dione	BATCHPRD_RP	20190625 23:12:31	01195329	PTARARAF	LRPLOYF1	S20:45:02	E23:12:31	-	-	-	C0000
#dione	BATCHPRD_RP	20190625 23:12:32	01195329	PTARARAF	CPYFTP	S23:12:32	E23:12:32	-	-	-	C0000
#dione	BATCHPRD_RP	20190625 23:12:34	01195329	PTARARAF	ZIPFICH	S23:12:33	E23:12:34	-	-	-	C0000
#dione	BATCHPRD_RP	20190625 23:12:35	01195329	PTARARAF	EMAIL	S23:12:34	E23:12:35	-	-	-	C0000
#dione	BATCHPRD_RP	20190625 23:12:35	01195329	PTARARAF	END_JOB	S23:12:35	E23:12:35	-	-	-	C0000
#dione	BATCHPRD_RP	20190625 23:12:37	01195329	PTARARAF	-	ENDED	C0000
#dione	BATCHPRD_RP	20190627 02:34:32	01195329	PTARARAF	-	AUTOPURGED	ARTJESADM	1_1	15794284