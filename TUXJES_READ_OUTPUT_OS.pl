#TUXJES_READ_OUTPUT_OS.pl

#le ficheiro criado por e prepara estatisticas
#TUXJES_OUTSYSTEMS_ALL.pl

use constant	WRITE_SMALL_FILE	=>	1;

#DESCRICAO DO REGISTO
use constant	LOG_FILE_NAME		=>	0;
use constant	SERVER				=>	1;
use constant	DOMAIN				=>	2;
use constant	JOB_NAME			=>	3;
use constant	JOB_CLASS			=>	4;
use constant	DAY_OF_WEEK			=>	5;
use constant	PART_OF_DAY			=>	6;		
use constant	WEEK_NUMBER			=>	7;
use constant	JOB_DATE			=>	8;
use constant	JOB_RUNTIME_SECONDS	=>	9;
use constant	RETURN_CODE			=>	10;

use strict;
use warnings;

use File::Basename;

my $ficheiro_de_entrada = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $ficheiro_de_entrada) {
	print "Ficheiro [$ficheiro_de_entrada] nao encontrado!\n";
	exit;
}

my %output;
my %output_class;
my %output_weekday;
my %output_partday;

my $key;

my @registo;

my ($in_lines, $out_lines) = (0,0);

my $ficheiro = basename($ficheiro_de_entrada);
$ficheiro =~ /(\d+)/;
$ficheiro = '/tmp/pkis/log_bi_os_'. $1 .'.csv';
my $filter_date = $1;

open my $fp,'<',$ficheiro_de_entrada or die "ERROR $!\n";
#salta primeiras 2 linhas, cabecalho
<$fp>;
<$fp>;
while(<$fp>) {

	$in_lines++;

	chomp;
	@registo = split(/;/);	
	
	#if($registo[RETURN_CODE] !~ /^C\d{4}$/) {
	#	print $registo[RETURN_CODE];
	#}
	#soh return_codes C.....
	next if($registo[RETURN_CODE] !~ /^C\d{4}$/);
	
	next if($registo[JOB_DATE] !~ /^2020-/);
				
	$key = $registo[LOG_FILE_NAME] .';'. $registo[DOMAIN] .';'. $registo[JOB_NAME];		
	
	$output{$key}{'QTY'} += 1;	
	$output{$key}{'TOTAL_SECONDS'} += $registo[JOB_RUNTIME_SECONDS];			
	
	if(!exists($output{$key}{'RUNTIMES'})) {
		$output{$key}{'RUNTIMES'} = $registo[JOB_RUNTIME_SECONDS];
	} else {
		$output{$key}{'RUNTIMES'} .= ';'. $registo[JOB_RUNTIME_SECONDS];
	}
		
	if(!exists($output{$key}{'MIN_VALUE'})) {
		$output{$key}{'MIN_VALUE'} = $registo[JOB_RUNTIME_SECONDS];
	}
	
	if(!exists($output{$key}{'MAX_VALUE'})) {
		$output{$key}{'MAX_VALUE'} = $registo[JOB_RUNTIME_SECONDS];
	}
	
	if($output{$key}{'MIN_VALUE'} > $registo[JOB_RUNTIME_SECONDS]) {
		$output{$key}{'MIN_VALUE'} = $registo[JOB_RUNTIME_SECONDS]; 
	}
	
	if($output{$key}{'MAX_VALUE'} < $registo[JOB_RUNTIME_SECONDS]) {
		$output{$key}{'MAX_VALUE'} = $registo[JOB_RUNTIME_SECONDS]; 
	}
	
#JOB CLASS

	$key = $registo[LOG_FILE_NAME] .';'. $registo[DOMAIN] .';'. $registo[JOB_CLASS];		
	
	$output_class{$key}{'QTY'} += 1;
	$output_class{$key}{'TOTAL_SECONDS'} += $registo[JOB_RUNTIME_SECONDS];			
	
#WEEK DAY

	$key = $registo[LOG_FILE_NAME] .';'. $registo[DOMAIN] .';'. $registo[DAY_OF_WEEK];		
	
	$output_weekday{$key}{'QTY'} += 1;
	$output_weekday{$key}{'TOTAL_SECONDS'} += $registo[JOB_RUNTIME_SECONDS];			

#PART_OF_DAY

	$key = $registo[LOG_FILE_NAME] .';'. $registo[DOMAIN] .';'. $registo[PART_OF_DAY];		
	
	$output_partday{$key}{'QTY'} += 1;
	$output_partday{$key}{'TOTAL_SECONDS'} += $registo[JOB_RUNTIME_SECONDS];			

	
}

close $fp;

if(WRITE_SMALL_FILE) {

	#if(!-e $ficheiro) {
		open $fp,'>:unix', $ficheiro or die "ERROR $!\n";	
		printf($fp "%s\n",$0);
		printf($fp "LOG_FILE_NAME;DOMAIN;JOB_NAME;JOB_RUNS;TOTAL_SECONDS;");
		printf($fp "MIN_VALUE;MAX_VALUE\n");
		#printf($fp "MIN_VALUE;MAX_VALUE;VARIACAO\n");
	#} else {
	#	open $fp,'>>:unix', $ficheiro or die "ERROR $!\n";
	#}
	
	foreach(sort keys %output) {
							
		$out_lines++;
		
		#$key = ($output{$_}{'MAX_VALUE'} - $output{$_}{'MIN_VALUE'})
		#		/ $output{$_}{'MIN_VALUE'} * 100;
			
		#printf($fp "%s;%d;%d;%d;%d;%.2f\n",
		printf($fp "%s;%d;%d;%d;%d\n",
			$_,
			$output{$_}{'QTY'},
			$output{$_}{'TOTAL_SECONDS'},
			$output{$_}{'MIN_VALUE'},
			$output{$_}{'MAX_VALUE'}
			#$key
		);
			
	}
	
	close $fp;

} else {

	#if(!-e $ficheiro) {
		open $fp,'>:unix', $ficheiro or die "ERROR $!\n";	
		printf($fp "%s\n",$0);
		printf($fp "LOG_FILE_NAME;DOMAIN;JOB_NAME;JOB_RUNS;TOTAL_SECONDS;");
		printf($fp "MIN_VALUE;MAX_VALUE;RUNTIMES\n");
	#} else {
	#	open $fp,'>>:unix', $ficheiro or die "ERROR $!\n";
	#}
	
	foreach(sort keys %output) {
							
		$out_lines++;
			
		@registo = split(/;/,$output{$_}{'RUNTIMES'});
		@registo = sort {$a <=> $b} @registo;
		
		printf($fp "%s;%d;%d;%d;%d;%s\n",
			$_,
			$output{$_}{'QTY'},
			$output{$_}{'TOTAL_SECONDS'},
			$output{$_}{'MIN_VALUE'},
			$output{$_}{'MAX_VALUE'},
			join(";",@registo)
			#$output{$_}{'RUNTIMES'}
		);
			
	}
	
	close $fp;
}

printf("%s ",$ficheiro);
printf("lines in: %d, lines out: %d\n",$in_lines, $out_lines);

printf("\nJOB CLASS\n");
printf("LOG_FILE_NAME;DOMAIN;JOB_CLASS;JOB_RUNS;TOTAL_SECONDS\n");
foreach(sort keys %output_class) {
	printf("%s;%d;%d\n",
	$_,
	$output_class{$_}{'QTY'},
	$output_class{$_}{'TOTAL_SECONDS'}
	,);
}

printf("\nJOB WEEK DAY\n");
printf("LOG_FILE_NAME;DOMAIN;DAY_OF_WEEK;JOB_RUNS;TOTAL_SECONDS\n");
foreach(sort keys %output_weekday) {
	printf("%s;%d;%d\n",
	$_,
	$output_weekday{$_}{'QTY'},
	$output_weekday{$_}{'TOTAL_SECONDS'}
	,);
}

printf("\nJOB DAY PART\n");
printf("LOG_FILE_NAME;DOMAIN;PART_OF_DAY;JOB_RUNS;TOTAL_SECONDS\n");
foreach(sort keys %output_partday) {
	printf("%s;%d;%d\n",
	$_,
	$output_partday{$_}{'QTY'},
	$output_partday{$_}{'TOTAL_SECONDS'}
	,);
}