#TUXJES_SCRAPPER.pl

use strict;
use warnings;

use lib 'lib';
require LogScrapperFunctions;

#DESCRICAO DO REGISTO
use constant	SERVIDOR		=>	0;
use constant	DOMAIN			=>	1;
use constant	DATA_HORA		=>	2;
use constant	JOB_NUMBER		=>	3;
use constant	JOB_NAME		=>	4;
use constant	JOB_STATUS		=>	6;		# ENDED
use constant	RETURN_CODE		=>	7;		# C0000

#ficheiros de log com menos de 1 MB
use constant	MAX_FILE_SIZE	=>	1000000;

#chomp(my $ficheiro_input = `ls -t1 \$JESROOT/jessyslog/jessys.log.* | head -1`); 

my $ficheiro_input = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $ficheiro_input) {
	LogScrapperFunctions::sendEmergencyEMAIL("TUXJES LOG FILE NOT FOUND!", "Ficheiro [$ficheiro_input] nao encontrado!");
	#print "Ficheiro [$ficheiro_input] nao encontrado!\n";
	exit;
}

my @registo;

my %emails;
my @directorias=();

my %found_job_errors;

open my $fp,'<',$ficheiro_input or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);
	next if(scalar @registo != 8);
	
	next if(substr($registo[JOB_NAME],1,1) eq 'T');		
	next if($registo[JOB_STATUS] !~ /^ENDED$/);				
	#next if($registo[RETURN_CODE] =~ /^(C0000|C0003|C0020|C0016)$/);				
	next if($registo[RETURN_CODE] =~ /^C0000$/);				
	
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
		
	$found_job_errors{$registo[JOB_NUMBER]}{'servidor'} = $registo[SERVIDOR];
	$found_job_errors{$registo[JOB_NUMBER]}{'data'} = LogScrapperFunctions::converteFormatoData($registo[DATA_HORA]);
	$found_job_errors{$registo[JOB_NUMBER]}{'domain'} =  $registo[DOMAIN];
	$found_job_errors{$registo[JOB_NUMBER]}{'job_name'} = $registo[JOB_NAME];
	$found_job_errors{$registo[JOB_NUMBER]}{'return_code'} = $registo[RETURN_CODE];
	
}
close $fp;

#------------------------------------------------------

@registo='';
foreach(sort keys %found_job_errors) {
	
	#printf("%s;%s;%s;%s;%s;%s\n",
	#	$found_job_errors{$_}{'servidor'},
	#	$found_job_errors{$_}{'data'},
	#	$found_job_errors{$_}{'domain'},
	#	$found_job_errors{$_}{'job_name'},
	#	$_,
	#	$found_job_errors{$_}{'return_code'}
	#);
	
	push @registo, sprintf("%s %-8s %-8s %5s",
		$found_job_errors{$_}{'data'},
		$found_job_errors{$_}{'job_name'},
		$_,
		$found_job_errors{$_}{'return_code'}
	);

}

foreach(@registo) {
	print $_,"\n";
}
#------------------------------------------------------
#SUB-ROTINAS
#------------------------------------------------------

sub get_log_file_size {

	my $filename = shift;
	
	my $size = -s $filename;
	
	if($size > MAX_FILE_SIZE) {
		LogScrapperFunctions::sendEmergencyEMAIL("File to BIG: " + $size, $filename);
	}
	
}

sub load_ficheiro_emails {

	if(!-e 'conf/emails.conf') {
		LogScrapperFunctions::sendEmergencyEMAIL("Ficheiro emails.conf nao encontrado!" , "Processo ABORTADO");
		exit;
	} else {
		open my $fp,'<','conf/emails.conf' or die "ERROR - emails.conf reader.\n";
		my @tmp;
		while(<$fp>) {
			chomp;
			@tmp = split(/;/);
			$emails{$tmp[0]} = {
				'sistema' => $tmp[1],
				'to' => $tmp[2]
			};
		}
		close $fp;
	}
	
}

sub load_ficheiro_directorias {

	if(!-e 'conf/directorias.conf') {
		LogScrapperFunctions::sendEmergencyEMAIL("Ficheiro directorias.conf nao encontrado!" , "Processo ABORTADO");
		exit;
	} else {
		open my $fp,'<','conf/directorias.conf' or die "ERROR - directorias.conf reader problem.\n";
		while(<$fp>) {
			chomp;
			push @directorias,$_;
		}
		close $fp;
	}
}







