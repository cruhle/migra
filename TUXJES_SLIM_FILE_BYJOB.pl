#TUXJES_SLIM_FILE_BYJOB.pl

#depois de correr o semanal por cada dominio
#juntar os ficheiros num soh ficheiro
#alterar o EOL para unix (CR/LF -> LF)
#renomear o ficheiro como weekly.csv

#DESCRICAO DO REGISTO
#use constant	SERVIDOR	=>	0;
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

use File::Basename;

use lib 'lib';
require DateCalcFunctions;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my %output;
my $key;
my $work;

my @registo;
my $domain;
my $s_data;
my $e_data;

my ($in_lines, $out_lines) = (0,0);

my $ficheiro = basename($parm);
$ficheiro =~ /(\d+)/;
$ficheiro = '/tmp/pkis/SLIM_FILE_BYJOB_XX_'. $1 .'.csv';

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	$in_lines++;

	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);
	next if(scalar @registo != 12);
	
	next if($registo[STEP_NAME] eq '-');
	next if(length($registo[START_TIME])!=9);
	next if(length($registo[END_TIME])!=9);	

	$s_data = (split(/\s/,$registo[DATA_HORA]))[0];
	$e_data = $s_data;
	
	$registo[START_TIME] =~ s/S//;	
	$registo[END_TIME] =~ s/E//;		
	
	if($registo[START_TIME] gt $registo[END_TIME]) {
		$s_data = DateCalcFunctions::getYesterdayYYYYMMDD($s_data);
	}
	
	$work = DateCalcFunctions::get_seconds_work_time(
			($s_data . ' ' . $registo[START_TIME]),
			($e_data . ' ' . $registo[END_TIME])
			);
	
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	$domain = $registo[DOMAIN];
	
	$key = getDateFormated($e_data) .';'. $domain .';'. $registo[JOB_NUMBER];
	
	if(exists($output{$key})) {
		$output{$key}{'worktime'} += $work;
		if($output{$key}{'return_code'} eq 'C0000') {
			$output{$key}{'return_code'} = $registo[RETURN_CODE];
		}
	} else {
		$output{$key}{'worktime'} = $work;
		$output{$key}{'jobname'} = $registo[JOB_NAME];
		$output{$key}{'return_code'} = $registo[RETURN_CODE];
	}
			
}

close $fp;

open my $fpo,'>', $ficheiro or die "ERROR $!\n";

printf($fpo "%s\n",$0);
printf($fpo "DATE;DOMAIN;JOB_NUMBER;JOB_NAME;JOB_RUNTIME_SECONDS;RETURN_CODE\n");
foreach(sort keys %output) {
	$out_lines++;
	printf($fpo "%s;%s;%d;%s\n",
			$_,
			$output{$_}{'jobname'},
			$output{$_}{'worktime'},
			$output{$_}{'return_code'}
		);
}
close $fpo;

$fp = $ficheiro;
$ficheiro =~ s/XX/$domain/g;
rename($fp, $ficheiro);

printf("%s\n",$ficheiro);
printf("Lines read: %d, lines written: %d\n",$in_lines, $out_lines);
#------------------------------------------------------

sub getDateFormated {

	my $z = shift;
	
	$z =~ /^(\d{4})(\d{2})(\d{2})$/;
	
	return sprintf("%d-%02d-%02d", $1, $2, $3);
}
