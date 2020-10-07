#TUXJES_MONITOR.pl

use constant	DEBUG	=>	1;

#set TUXJESDOMAIN=RP|CO|FO

#cilene	BATCHPRD_CO	20200122 15:13:14	00844231	PTTME006	-	ENDED	C0000

#DIRECTORIAS PARA FICHEIRO DE LOG
#VARS->DOMAIN
#VARS->JOB NUMBER
#VARS->JOB NUMBER

#/PRD/EXE_COBOL/PROD/%s/tux/JESROOT/%s/LOG/%s.log
#/PRD/EXE_COBOL/PROD/%s/tux/JESROOT/%s.bak/LOG/%s.log
#/PRD/EXE_COBOL/PROD/%s/tux/JESROOT_BCK/%s.bak/LOG/%s.log

#ARTSTATUS FILE LOCATION
#one line file contents

#	TYPRUN=*,QUEUE=OUTPUT,STATUS=DONE,CLASS=A,OWNER=co_prd,
#	JOBNAME=PISTAB05,SUBMITTIME=1580136707,PRTY=13,MACHINE=0,
#	PID=63636366,EXECTIME=1580136709,ENDTIME=1580136713,USRSEC=1,
#	USRUSEC=214774,SYSSEC=1,SYSUSEC=607017

#VARS->DOMAIN
#VARS->JOB NUMBER

#/PRD/EXE_COBOL/PROD/%s/tux/JESROOT/%s/artstatus
#/PRD/EXE_COBOL/PROD/%s/tux/JESROOT/%s.bak/artstatus
#/PRD/EXE_COBOL/PROD/%s/tux/JESROOT_BCK/%s.bak/artstatus

#DESCRICAO DO REGISTO
use constant	SERVER		=>	0;
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
#ENDED
use constant	JOB_STATUS	=>	6;	
use constant	RETURN_CODE	=>	7;

use strict;
use warnings;

use File::Basename;

use lib 'lib';
require DateFunctions;
require FileFunctions;

my $ficheiro_de_entrada = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $ficheiro_de_entrada) {
	print "Ficheiro [$ficheiro_de_entrada] nao encontrado!\n";
	exit;
}

my %output;

my @registo;

my ($in_lines, $out_lines, $key) = (0,0,0);

my $data_log = FileFunctions::getFileName($ficheiro_de_entrada);
$data_log =~ /(\d+)/;
$data_log = $1;

my ($ficheiro_de_log, $ficheiro_size) = (FileFunctions::getFileNameSize($ficheiro_de_entrada));
my $run_date_time = DateFunctions::getLocaltime();

my $domain = $ENV{"TUXJESDOMAIN"} || 'null';

my $fpDEBUG;
my $fileDEBUG = 'datafiles/' . sprintf("%s_%s.debug",$domain,DateFunctions::getCurrentDateYYYYMMDD());

open $fpDEBUG,'>>:unix','datafiles/journal.log';
printf($fpDEBUG "%s\t%s\n",$domain, DateFunctions::getLocaltime());
close $fpDEBUG;

if(DEBUG) {
	open $fpDEBUG,'>>:unix',$fileDEBUG or die "ERROR debug FILE.$!\n";
	printf($fpDEBUG "TRACE LOG STARTING ----------------------------\n");
	printf($fpDEBUG "%s\n",DateFunctions::getLocaltime());
	printf($fpDEBUG "Tuxjes file to read: %s\n",$ficheiro_de_entrada);
	printf($fpDEBUG "Tuxjes file size: %d\n",$ficheiro_size);
}

#DOMAIN_MMDDAA.dat
my $control_file = 'datafiles/' . sprintf("%s_%s.dat",$domain,$data_log);

my $start_read_from=0;

if(-e $control_file) {
	open my $fp,'<',$control_file or die "ERROR - CONTROL-FILE!\n";
	$start_read_from = <$fp>;
	close $fp;
}

if(DEBUG) {
	printf($fpDEBUG "Log file to read: %s\n",$control_file);
	printf($fpDEBUG "Start read from: %d\n",$start_read_from);
	
	printf($fpDEBUG "%s;%s;%s;%d;%s\n",
	DateFunctions::getLocaltime(),
	$domain, $ficheiro_de_log, $ficheiro_size, $control_file);
}

if($start_read_from>=$ficheiro_size) {
#nada a fazer, log file rodou?
	exit;
}

#my $ficheiro = '/tmp/pkis/log_monitor_'. $data_log .'.csv';
my $ficheiro = 'logs/log_monitor_'. $data_log .'.csv';

open my $fp,'<',$ficheiro_de_entrada or die "ERROR $!\n";
seek($fp,$start_read_from,0);

while(<$fp>) {

	$in_lines++;

	next if($_ !~ /^(cilene|dione)/);
	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);	
		
	next if($registo[JOB_STATUS] !~/ENDED/);		
	next if($registo[RETURN_CODE] =~/C0\d{3}/);		
	
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	
	$key = $registo[JOB_NUMBER];
	
	$output{$key}{'SERVER'} = $registo[SERVER];	
	$output{$key}{'JOB_NAME'} = $registo[JOB_NAME];	
	$output{$key}{'DATE_TIME'} = $registo[DATA_HORA];	
	$output{$key}{'DOMAIN'} = $registo[DOMAIN];		
	$output{$key}{$registo[JOB_STATUS]} = $registo[JOB_STATUS];	
	$output{$key}{'RETURN_CODE'} = $registo[RETURN_CODE];	
			
}

close $fp;

open $fp,'>:unix',$control_file;
printf($fp "%d",$ficheiro_size);
close $fp;

if(!-e $ficheiro) {
	open $fp,'>:unix', $ficheiro or die "ERROR $!\n";	
	printf($fp "%s\n",$0);
	printf($fp "RUN_DATE_TIME;LOG_DATE_TIME;SERVER;DOMAIN;JOB_NUMBER;JOB_NAME;RETURN_CODE\n");	
} else {
	open $fp,'>>:unix', $ficheiro or die "ERROR $!\n";
}

foreach(sort keys %output) {
				
	$out_lines++;
		
	printf($fp "%s;%s;%s;%s;%s;%s;%s\n",
		$run_date_time,
		$output{$_}{'DATE_TIME'},
		$output{$_}{'SERVER'},
		$output{$_}{'DOMAIN'},
		$_,
		$output{$_}{'JOB_NAME'},		
		$output{$_}{'RETURN_CODE'}
	);
		
}

close $fp;

if(DEBUG) {
	printf($fpDEBUG "Log file written to: %s\n",$ficheiro);
	printf($fpDEBUG "Lines in: %d, lines out: %d\n",$in_lines, $out_lines);
	printf($fpDEBUG "%s\n",DateFunctions::getLocaltime());
	printf($fpDEBUG "TRACE LOG ENDING ------------------------------\n");
	close $fpDEBUG;
}	

