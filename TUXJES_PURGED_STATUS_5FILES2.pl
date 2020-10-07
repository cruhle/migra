#TUXJES_PURGED_STATUS_5FILES2.pl

#REGISTO DO FICHEIRO DE LOG
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	JOB_STATUS	=>	6;
use constant	RETURN_CODE	=>	7;

#constants for write file
use constant	SUBMITTED	=>	1;
use constant	STARTED		=>	2;
use constant	ENDED		=>	4;
use constant	AUTOPURGED	=>	8;
use constant	COMPLETE	=>	15;

use strict;
use warnings;
use integer;

use File::Basename;

use lib 'lib';
require DateCalcFunctions;

my @registo;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

my $ficheiro_cpl = basename($parm);
$ficheiro_cpl =~ /(\d+)/;
$ficheiro_cpl = '/tmp/pkis/PURGED_DATA_XX_'. $1 .'.csv';			#COMPLETO
#_inc => incompleto, nem todos os campos preenchidos
my $ficheiro_sub = '/tmp/pkis/PURGED_DATA_XX_SUB_'. $1 .'.csv';		#SUBMITTED
my $ficheiro_sta = '/tmp/pkis/PURGED_DATA_XX_STA_'. $1 .'.csv';		#STARTED
my $ficheiro_end = '/tmp/pkis/PURGED_DATA_XX_END_'. $1 .'.csv';		#ENDED
my $ficheiro_aut = '/tmp/pkis/PURGED_DATA_XX_AUT_'. $1 .'.csv';		#AUTOPURGED

my $fp;
my $domain;

my %jobs;

open $fp,'<',$parm or die "ERROR $!\n";
printf("Reading %s ....\n\n",$parm);

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	
	next if($_ !~ /(SUBMITTED|AUTOPURGED|STARTED|ENDED)/);
	@registo = split(/\t/);					
	
	#next if($registo[JOB_NAME] !~ /^PIFMFC/);
		
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	
	$domain = $registo[DOMAIN];
	
	$jobs{$registo[JOB_NUMBER]}{$registo[JOB_STATUS]} = $registo[DATA_HORA];
	$jobs{$registo[JOB_NUMBER]}{'DOMAIN'} = $registo[DOMAIN];
	$jobs{$registo[JOB_NUMBER]}{'JOB_NAME'} = $registo[JOB_NAME];
	
	if($registo[JOB_STATUS] eq 'ENDED') {
		$jobs{$registo[JOB_NUMBER]}{'RETURN_CODE'} = $registo[RETURN_CODE];
	}
			
}

close $fp;

$ficheiro_cpl =~ s/XX/$domain/g;
$ficheiro_sub =~ s/XX/$domain/g;
$ficheiro_sta =~ s/XX/$domain/g;
$ficheiro_end =~ s/XX/$domain/g;
$ficheiro_aut =~ s/XX/$domain/g;

open my $fpo_cpl,'>', $ficheiro_cpl or die "ERROR $!\n";
printf($fpo_cpl "%s\n",$0);
printf($fpo_cpl "%s\n","jobs.csv");
printf($fpo_cpl "JOB_NUMBER;JOB_NAME;DOMAIN;SUBMITTED;STARTED;ENDED;AUTOPURGED;JOB_RUNTIME_SECONDS;RETURN_CODE\n");

open my $fpo_sub,'>', $ficheiro_sub or die "ERROR $!\n";
printf($fpo_sub "%s\n",$0);
printf($fpo_sub "%s\n","submitted.csv");
printf($fpo_sub "JOB_NUMBER;JOB_NAME;DOMAIN;SUBMITTED\n");

open my $fpo_sta,'>', $ficheiro_sta or die "ERROR $!\n";
printf($fpo_sta "%s\n",$0);
printf($fpo_sta "%s\n","started.csv");
printf($fpo_sta "JOB_NUMBER;JOB_NAME;DOMAIN;STARTED\n");

open my $fpo_end,'>', $ficheiro_end or die "ERROR $!\n";
printf($fpo_end "%s\n",$0);
printf($fpo_end "%s\n","ended.csv");
printf($fpo_end "JOB_NUMBER;JOB_NAME;DOMAIN;ENDED;RETURN_CODE\n");

open my $fpo_aut,'>', $ficheiro_aut or die "ERROR $!\n";
printf($fpo_aut "%s\n",$0);
printf($fpo_aut "%s\n","autopurged.csv");
printf($fpo_aut "JOB_NUMBER;JOB_NAME;DOMAIN;AUTOPURGED\n");

my $status = 0;

my ($counter_cpl, $counter_inc) = (0,0);

foreach(sort keys %jobs) {

	$status = 15;
	
	if(!exists($jobs{$_}{'SUBMITTED'})) {
		$jobs{$_}{'SUBMITTED'}='19700101 00:00:00';
		$status-=SUBMITTED;
	}

	if(!exists($jobs{$_}{'STARTED'})) {
		$jobs{$_}{'STARTED'}='19700101 00:00:00';
		$status-=STARTED;
	}
	
	if(!exists($jobs{$_}{'ENDED'})) {
		$jobs{$_}{'ENDED'}='19700101 00:00:00';
		$jobs{$_}{'RETURN_CODE'}='';
		$status-=ENDED;
	}
	
	if(!exists($jobs{$_}{'AUTOPURGED'})) {
		$jobs{$_}{'AUTOPURGED'}='19700101 00:00:00';
		$status-=AUTOPURGED;
	}
	
	if(($status & COMPLETE) == COMPLETE) {
		$counter_cpl += 1;
		printf($fpo_cpl "%s;%s;%s;%s;%s;%s;%s;%d;%s\n",
			$_,
			$jobs{$_}{'JOB_NAME'},
			$jobs{$_}{'DOMAIN'},
			$jobs{$_}{'SUBMITTED'},
			$jobs{$_}{'STARTED'},
			$jobs{$_}{'ENDED'},
			$jobs{$_}{'AUTOPURGED'},
			
			DateCalcFunctions::get_seconds_work_time(
				$jobs{$_}{'STARTED'},$jobs{$_}{'ENDED'}
			),
			$jobs{$_}{'RETURN_CODE'}
		);
	} else {
		$counter_inc++;
		if(($status & SUBMITTED) == SUBMITTED) {
			printf($fpo_sub "%s;%s;%s;%s\n",
				$_,
				$jobs{$_}{'JOB_NAME'},
				$jobs{$_}{'DOMAIN'},
				$jobs{$_}{'SUBMITTED'}				
			);	
		} 
		
		if (($status & STARTED) == STARTED) {
			printf($fpo_sta "%s;%s;%s;%s\n",
				$_,
				$jobs{$_}{'JOB_NAME'},
				$jobs{$_}{'DOMAIN'},
				$jobs{$_}{'STARTED'}				
			);
		} 
		
		if (($status & ENDED) == ENDED) {
			printf($fpo_end "%s;%s;%s;%s;%s\n",
				$_,
				$jobs{$_}{'JOB_NAME'},
				$jobs{$_}{'DOMAIN'},
				$jobs{$_}{'ENDED'},
				$jobs{$_}{'RETURN_CODE'}
			);
		} 
		
		if (($status & AUTOPURGED) == AUTOPURGED) {
			printf($fpo_aut "%s;%s;%s;%s\n",
				$_,
				$jobs{$_}{'JOB_NAME'},
				$jobs{$_}{'DOMAIN'},
				$jobs{$_}{'AUTOPURGED'}				
			);
		}
	
	}

}

close $fpo_cpl;
close $fpo_sub;
close $fpo_sta;
close $fpo_end;
close $fpo_aut;

printf("COMPLETO    %-45s %d\n",$ficheiro_cpl, $counter_cpl);
printf("INCOMPLETO  %-45s %d\n\n","", $counter_inc);
printf("SUBMITTED   %-45s\n",$ficheiro_sub);
printf("STARTED     %-45s\n",$ficheiro_sta);
printf("ENDED       %-45s\n",$ficheiro_end);
printf("AUTOPURGED  %-45s\n",$ficheiro_aut);
printf("\nTOTAL       %-45s %d\n",'', ($counter_cpl + $counter_inc));
#printf("INCOMPLETO: %s %d\n",$ficheiro_inc, $counter_inc);

#-
#-carrega uma tabela com os dados completos
#-carrega outra tabela com os dados dos outros quatro ficheiros
#-tem uma coluna a mais, COUNTER, soh nesta tabela de movimento.
#-JOB_NUMBER;JOB_NAME;DOMAIN;SUBMITTED;STARTED;ENDED;AUTOPURGED;JOB_RUNTIME_SECONDS;RETURN_CODE;COUNTER
#-se INSERT COUNTER = 1
#-se UPDATE COUNTER++
#-se COUNTER == 4
#-calcular o JOB_RUNTIME_SECONDS usando o ORACLE com um UPDATE directo
#-(ENDED - STARTED) seconds
#-no fim de tudo passa para a tabela principal todos os
#-registos em que COUNTER == 4 (registo completo)
#-apaga da tabela de movimento todos os registo em
#-que o COUNTER == 4
#-


