#TUXJES_LAST_DAY.pl

#/DEV/user/cobol_dv/load_csv

#INPUT ficheiro do log

use strict;
use warnings;
use File::Basename;

use Time::Piece ();
use Time::Seconds;

use lib 'lib';
require DateCalcFunctions;

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

my $data_para_filtrar = '20190721';

my $filename = basename($parm);
$filename =~ /(\d+)/;
$filename = '/tmp/pkis/jobs_last_day_XX_'. $1 .'.csv';

my @registo;
my %contador;
my %jobs;
my ($domain, $key, $data) = ('', '', '');
my ($start_time, $end_time, $work, $steps, $total_jobs)=(0, 0, 0, 0, 0);

open my $fp,'<',$parm or die "ERROR $!\n";
while(<$fp>) {

	next if(length $_ < 20);
	
	next if(/STARTED/);
	next if(/ENDED/);
	next if(/SUBMITTED/);
	next if(/AUTOPURGED/);
	
	chomp;
	@registo = split(/\t/);			
		
	#next if((split(/\s/,$registo[DATA_HORA]))[0] ne $data_para_filtrar );
	
	next if(scalar @registo != 12);
	next if(length($registo[STEP_NAME]) eq '-');
	next if(length($registo[START_TIME])!=9);
	next if(length($registo[END_TIME])!=9);
			
	$start_time = DateCalcFunctions::time_2_seconds(substr($registo[START_TIME],1));
	$end_time = DateCalcFunctions::time_2_seconds(substr($registo[END_TIME],1));		
	$work = DateCalcFunctions::valida_tempos($start_time, $end_time);	
	
	$data = (split(/\s/,$registo[DATA_HORA]))[0];
	
	$registo[DOMAIN] =~ s/BATCHPRD_//;
	$domain = $registo[DOMAIN];
	
	$key = $data .';'. $domain;
	
	if(exists($contador{$key})) {
		$contador{$key}{'work'} += $work;
		$contador{$key}{'steps'} += 1;
	} else {
		$contador{$key} = {
			'work' => $work,
			'steps' => 1
		};
	}
	
	$key .= ';' . $registo[JOB_NUMBER];
	$jobs{$key} += 1;		
	
}
close $fp;

#open my $fpout,'>',$filename or die "ERROR $$!\n";
#printf($fpout "[%s]\n",$0);
#printf($fpout "DATA;DOMAIN;TOTAL_JOBS;TOTAL_STEPS;TOTAL_TIME_SECONDS;TOTAL_TIME\n");
my %xjobs;

#prepara o total de jobs por domain+dia
#compara com yyyymmdd;XX
foreach(sort keys %jobs) {
	$xjobs{substr($_,0,11)} += 1;
}

foreach(sort keys %contador) {
		
	#printf("%s;%d;%d;%d;%s\n", 
	printf("%s;%d;%d;%d\n", 
		$_,
		$xjobs{$_},
		$contador{$_}{'steps'}, 
		$contador{$_}{'work'} 
		#,DateCalcFunctions::seconds_2_time($contador{$_}{'work'})
	);

}

#close $fpout;

#$fp = $filename;
#$fp =~ s/XX/$domain/g;
#
#rename($filename, $fp);
#
#printf("[%s]\n",$fp);


