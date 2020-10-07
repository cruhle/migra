#TUXJES_ETL_V2.pl

#REGISTO DO FICHEIRO DE LOG
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
use File::Basename;

use lib 'lib';
require DateCalcFunctions;

my ($parm) =  @ARGV; 

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my @registo;
my $start_time=0;
my $end_time=0;
my $work;

my $code;

my %step_counter;

my $area = 'XX';

my $linhas = 0;

my $filename = basename($parm);

$filename =~ s/log/$area/;
$filename =~ s/\./_/g;
$filename.='.del';

$filename = '/tmp/pkis/'. $filename;

open my $fp,'<',$parm or die "ERROR $!\n";

open my $fpo,'>',$filename or die "ERROR $!\n";
printf($fpo "%s\n",$0);
printf($fpo "DATE_TIME;DOMAIN;JOB_NUMBER;JOB_NAME;STEP_NAME;STEP_NUMBER;TIME_SECONDS;RETURN_CODE\n");

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);
		
	next if(scalar @registo != 12);
	next if($registo[STEP_NAME] eq '-');			
	next if(length($registo[START_TIME])!=9);
	next if(length($registo[END_TIME])!=9);
	
	$start_time = DateCalcFunctions::time_2_seconds(substr($registo[START_TIME],1));
	$end_time = DateCalcFunctions::time_2_seconds(substr($registo[END_TIME],1));
	$work = DateCalcFunctions::valida_tempos($start_time, $end_time);
	
	if($area eq 'XX') {
		$registo[DOMAIN] =~ s/BATCHPRD_//;	
		$area = $registo[DOMAIN];		
	}
	
	$step_counter{$registo[JOB_NUMBER]}+=1;
	$linhas++;
	
	printf($fpo "%s;%s;%s;%s;%s;%d;%d;%s\n",
		DateCalcFunctions::data_hora($registo[DATA_HORA]),
		$area,
		$registo[JOB_NUMBER],
		$registo[JOB_NAME],
		$registo[STEP_NAME],
		$step_counter{$registo[JOB_NUMBER]},
		$work,
		$registo[RETURN_CODE]
		);	
	
}
close $fpo;
close $fp;

$fp = $filename;
$fp =~ s/XX/$area/g;

rename($filename, $fp);

if($linhas>0) {
	#printf("Ficheiro [%s] criado, com [%d] linhas.\n",$fp, $linhas);
	printf("%s;%d\n",$fp, $linhas);
} else {
	unlink($fp);
	printf("File deleted: %s\n",$fp);
}


