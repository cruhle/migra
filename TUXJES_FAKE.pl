#TUXJES_FAKE.pl

#dboraprdrg4.tap.pt
#U_SUGTMG_CRUHLE
#11521
#TDBORA4

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

use lib 'lib';
require DateCalcFunctions;

my $m = shift || die "Usage: $0 yyyymm date to process\n";

if($m !~ /^[0-9]{6,8}$/) {
	printf("FORMATO => YYYYMM[DD]\n");
	exit;
}


my @registo;
my $work;
my $area;
my $start_time;
my $end_time;
my $data;
my $fp;
my $parm;
my $key;

my %data_job;
my %jobs;

my @lista_de_ficheiros = ('datafiles/co.txt','datafiles/fo.txt',
	'datafiles/rp.txt','datafiles/pr.txt','datafiles/misc.txt');

#@lista_de_ficheiros = ('datafiles/rp.txt');

my $data_filtro;
my $ficheiro_de_dados;
my $fptemp;

foreach $parm(@lista_de_ficheiros) {
	
	open $fptemp,'<',$parm or die "Error $!\n";
	
	while(<$fptemp>) {
	
		chomp;
		($data_filtro, $ficheiro_de_dados) = split(/:/);
		#next if($data_filtro ne $m);
		#printf("%s\t%s\n",$data_filtro, $m);
		#next if($data_filtro !~ /^$m$/);		
		
		next if(index($m,$data_filtro)==-1);
	
		if(!-e $ficheiro_de_dados) {
			printf("%s .. not found!\n",$ficheiro_de_dados);
			next;
		}
		
		open $fp,'<',$ficheiro_de_dados or die "ERROR $!\n";
		printf("%s\n",$ficheiro_de_dados);
		while(<$fp>) {
		
			next if(length $_ < 20);
			
			chomp;
			@registo = split(/\t/);
			next if(scalar @registo != 12);
			
			next if($registo[STEP_NAME] eq '-');
			next if(length($registo[START_TIME])!=9);
			next if(length($registo[END_TIME])!=9);
			
			$data = (split(/\s/,$registo[DATA_HORA]))[0];
			
			next if($data !~ /^$m/);
			
			#passa hh:mm:ss para hh:00:00
			if(!exists($data_job{$registo[JOB_NUMBER]})) {
				$data_job{$registo[JOB_NUMBER]} = substr($registo[DATA_HORA],0,12) . '00:00';
			}
			$registo[DATA_HORA] = $data_job{$registo[JOB_NUMBER]};		
						
			$start_time = substr($registo[START_TIME],1);
			$end_time = substr($registo[END_TIME],1);	

			#printf("%s %s %s %s ",
			#	$registo[DATA_HORA],
			#	$registo[JOB_NUMBER],
			#	$start_time,
			#	$end_time
			#	);
		
			if($start_time gt $end_time) {
				$end_time = $data .' '. $end_time;
				$data = DateCalcFunctions::getYesterdayYYYYMMDD($data);
				$start_time = $data .' '. $start_time;
			} else {
				$start_time = $data .' '. $start_time;
				$end_time = $data .' '. $end_time;
			}
									
			$work = DateCalcFunctions::get_seconds_work_time($start_time, $end_time);
						
			#printf("%d\n",$work);
			
			$registo[DOMAIN] =~ s/BATCHPRD_//;	
			
			$key = $registo[DATA_HORA] .';'. $registo[DOMAIN] .';'. $registo[JOB_NAME];
			
			$jobs{$key}{'runtime'} += $work;
			
			if(exists($jobs{$key}{'job_number'})) {
				if($jobs{$key}{'job_number'} ne $registo[JOB_NUMBER]) {
						$jobs{$key}{'qtd'} += 1;
						$jobs{$key}{'job_number'} = $registo[JOB_NUMBER];
				}
			} else {			
				$jobs{$key}{'job_number'} = $registo[JOB_NUMBER];
				$jobs{$key}{'qtd'} = 1;
			}				
					
		}
		
		close $fp;
	}	
	
	close $fptemp;
}	

my %outTimes;

foreach(sort keys %jobs) {
	$fp = getKey($_);
	if(exists($outTimes{$fp})) {
		$outTimes{$fp}{'qtd'} += $jobs{$_}{'qtd'};
		$outTimes{$fp}{'runtime'} += $jobs{$_}{'runtime'};
	} else {
		$outTimes{$fp}{'qtd'} = $jobs{$_}{'qtd'};
		$outTimes{$fp}{'runtime'} = $jobs{$_}{'runtime'};
	}
}

my $ficheiro = '/tmp/pkis/DATA_FILE_'. $m .'.csv';
open my $fpo,'>', $ficheiro or die "ERROR $!\n";
printf($fpo "%s\n",$0);
printf($fpo "DATE_TIME;DOMAIN;JOB_RUNS;RUNTIME_SECONDS\n");

foreach(sort keys %outTimes) {
	printf($fpo "%s;%d;%d\n",
		converteKEY($_),
		$outTimes{$_}{'qtd'},
		$outTimes{$_}{'runtime'}
	);
}
close $fpo;

printf("\n%s criado.\n",$ficheiro);
#------------------------------------------------------
sub getKey {
	my $param = shift;
	my @data = split(/;/,$param);
	return ($data[0].';'.$data[1]);
}

sub converteKEY {

	my $param = shift;
	my @data = split(/;/,$param);
	$data[0] = substr($data[0],0,4)."-".substr($data[0],4,2)."-".substr($data[0],6,2)." ".substr($data[0],9);
	
	return ($data[0].';'.$data[1]); #.';'.$data[2]);
}
#------------------------------------------------------

