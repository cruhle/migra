#TUXJES_DAILY_SUMMARY.pl

# INPUT
# /tmp/pkis/DAILY_aaaammdd.csv

#TUXJES_SLIM_FILE_DAILY.pl
#DATE;DOMAIN;JOB_NUMBER;JOB_NAME;JOB_RUNTIME_SECONDS;RETURN_CODE
#20191117;CO;00690825;POROBOTS;3;C0000
#20191117;CO;00690826;PTIMSCOS;1;C0000

use constant	DATA				=>	0;
use constant	DOMAIN				=>	1;
use constant	JOB_NUMBER			=>	2;
use constant	JOB_NAME			=>	3;
use constant	RUNTIME_SECONDS		=>	4;
use constant	RETURN_CODE			=>	5;

use strict;
use warnings;
use File::Basename;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my %jobs;
my @registo;

my $ficheiro = basename($parm);
$ficheiro =~ /(\d+)/;
$ficheiro = '/tmp/pkis/DAILY_SUMMARY_'. $1 .'.csv';

my $data = $1;
$data =~ /(\d{4})(\d{2})(\d{2})/;
$data = sprintf("%04d-%02d-%02d",$1,$2,$3);
open my $fp,'<',$parm or die "ERROR $!\n";

#skip first 2 lines! HEADER LINES!
<$fp>;
<$fp>;

while(<$fp>) {

	chomp;
	@registo = split(/;/);
	
	if(exists($jobs{$registo[JOB_NAME]})) {
		$jobs{$registo[JOB_NAME]}{'JOB_RUNS'} += 1;
		$jobs{$registo[JOB_NAME]}{'RUNTIME_SECONDS'} += $registo[RUNTIME_SECONDS];
###		if($jobs{$registo[JOB_NAME]}{'RETURN_CODE'} ne 'C0000') {
###			$jobs{$registo[JOB_NAME]}{'RETURN_CODE'} = $registo[RETURN_CODE];
###		}
		if($jobs{$registo[JOB_NAME]}{'MIN_SECONDS'} > $registo[RUNTIME_SECONDS]) {
			$jobs{$registo[JOB_NAME]}{'MIN_SECONDS'} = $registo[RUNTIME_SECONDS];
		}
		if($jobs{$registo[JOB_NAME]}{'MAX_SECONDS'} < $registo[RUNTIME_SECONDS]) {
			$jobs{$registo[JOB_NAME]}{'MAX_SECONDS'} = $registo[RUNTIME_SECONDS];
		}
		
		$jobs{$registo[JOB_NAME]}{'RUNS'} .= ':' . $registo[RUNTIME_SECONDS];
		
	} else {
		$jobs{$registo[JOB_NAME]}{'JOB_RUNS'} = 1;
###		$jobs{$registo[JOB_NAME]}{'RETURN_CODE'} = $registo[RETURN_CODE];		
		$jobs{$registo[JOB_NAME]}{'DOMAIN'} = $registo[DOMAIN];
		$jobs{$registo[JOB_NAME]}{'MIN_SECONDS'} = $registo[RUNTIME_SECONDS];
		$jobs{$registo[JOB_NAME]}{'MAX_SECONDS'} = $registo[RUNTIME_SECONDS];
		$jobs{$registo[JOB_NAME]}{'RUNTIME_SECONDS'} = $registo[RUNTIME_SECONDS];
		
		$jobs{$registo[JOB_NAME]}{'RUNS'} = $registo[RUNTIME_SECONDS];
	}
			
}

close $fp;

open $fp,'>', $ficheiro or die "ERROR $!\n";	
printf($fp "%s\n",$0);
###printf($fp "DATA;JOB_NAME;DOMAIN;JOB_RUNS;TOTAL_RUNTIME_SECONDS;RUNTIME_SECONDS_MIN;RUNTIME_SECONDS_MAX;RETURN_CODE\n");
printf($fp "DATA;JOB_NAME;DOMAIN;JOB_RUNS;TOTAL_RUNTIME_SECONDS;RUNTIME_SECONDS_MIN;RUNTIME_SECONDS_MAX\n");

foreach(sort keys %jobs) {

###	printf($fp "%s;%s;%s;%d;%d;%d;%d;%s\n",
	printf($fp "%s;%s;%s;%d;%d;%d;%d\n",
			$data,
			$_,
			$jobs{$_}{'DOMAIN'},
			$jobs{$_}{'JOB_RUNS'},
			$jobs{$_}{'RUNTIME_SECONDS'},
			$jobs{$_}{'MIN_SECONDS'},
			$jobs{$_}{'MAX_SECONDS'} ###,
###			$jobs{$_}{'RETURN_CODE'}
		);
			
}
close $fp;

printf("%s\n",$ficheiro);

my $fdata = $data;
$fdata =~ s/-//g;
#
my $base_directory = '/tmp/pkis/' . $fdata .'/';
my $tmp_dir;


$ficheiro =~ s/SUMMARY/JOBS_RUNTIME_ONLY/;
open $fp,'>', $ficheiro or die "ERROR $!\n";	
printf($fp "%s\n",$0);
printf($fp "%s;%s;%s;%s\n","DATA","DOMAIN","JOB_NAME","JOB_RUNS");

foreach(sort keys %jobs) {
		
	#soh escreve jobs com 10 execucoes
	#next if($jobs{$_}{'JOB_RUNS'} != 10);
	
	#soh escreve jobs com mais de 3 runs
	#next if($jobs{$_}{'JOB_RUNS'} < 4);
	
	printf($fp "%s;%s;%s;%s\n",
		$data,
		$jobs{$_}{'DOMAIN'},
		$_,		
		$jobs{$_}{'RUNS'}
	);


	next; #volta para cima, nao faz a parte de baixo :-)
	
	next if($jobs{$_}{'JOB_RUNS'} != 10);
	
	$tmp_dir = $base_directory; 
	if(!-d $tmp_dir) {
		mkdir($tmp_dir);
	}
	
	$tmp_dir = $base_directory . $jobs{$_}{'DOMAIN'};
	if(!-d $tmp_dir) {
		mkdir($tmp_dir);
	}
	
	$tmp_dir .= '/' . $_ . '.graph';  #JOB_NAME
	
	grava_ficheiro_grafico(
		$jobs{$_}{'MIN_SECONDS'},
		$jobs{$_}{'MAX_SECONDS'},
		$jobs{$_}{'RUNS'},
		$tmp_dir
		);
}

close $fp;

printf("%s\n",$ficheiro);

#------------------------------------------

sub grava_ficheiro_grafico {

	my ($mi, $ma, $valores, $ficheiro) = @_;
	
	$mi = ($mi==0?1:$mi);
	$ma = ($ma==0?1:$ma);
	
	my @registo = split /:/,$valores;
	
	open my $fpi,'>',$ficheiro;
	foreach(@registo) {
		printf($fpi "%6d\t%.6f\n",
			$_,($_ - $mi) / ($ma - $mi));	
	}
	close $fpi;

}

#------------------------------------------


