#TUXJES_SIMPLE_ONE.pl

#le output de TUXJES_OUTSYSTEMS_SIMPLE.pl
#log_os_XX_clean_mmddaa.csv

#sqlldr u_sugtmg_cruhle@tdbora4 control=load_weekly.ctl data=ficheiro-input

#DESCRICAO DO REGISTO
use constant	JOB_DATE				=>	0;
use constant	DOMAIN					=>	1;
use constant	JOB_NAME				=>	2;
use constant	JOB_CLASS				=>	3;
use constant	PART_OF_DAY				=>	4;
use constant	JOB_RUNTIME_SECONDS		=>	5;
use constant	RETURN_CODE				=>	6;

use strict;
use warnings;

use Time::Piece;
use File::Basename;

my $ficheiro_de_entrada = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $ficheiro_de_entrada) {
	print "Ficheiro [$ficheiro_de_entrada] nao encontrado!\n";
	exit;
}

my %output;
my %jobs;
my %sums;

my $key;
my $job_date;
my $domain;

my @registo;

my ($in_lines, $out_lines) = (0,0);

my $ficheiro = basename($ficheiro_de_entrada);
$ficheiro =~ /(\d+)/;

$ficheiro = '/tmp/pkis/days_'. $1 .'.csv';
#copiar p/powerbi_refresh/days.csv

#####my $ficheiro_jobs = '/tmp/pkis/jobs_'. $1 .'.csv';

my $ficheiro_sums = '/tmp/pkis/sums_'. $1 .'.csv';

my $filter_date = $1;
$filter_date =~ /(\d{2})(\d{2})(\d{2})/;
$filter_date = ($3 + 2000).''.$1.''.$2;

open my $fp,'<',$ficheiro_de_entrada or die "ERROR $!\n";
#skip header lines 2
<$fp>;
<$fp>;
while(<$fp>) {

	$in_lines++;
	
	chomp;
	@registo = split(/;/);	
	
#####	$jobs{$registo[JOB_NAME]}+=1;
	
	$domain = $registo[DOMAIN];
	$job_date = (split(/\s/,$registo[JOB_DATE]))[0];
	
	$key = $job_date .';'. $registo[DOMAIN] .';'. $registo[JOB_NAME];	
	
	$output{$key}{'job_runs'} += 1;	
	$output{$key}{'seconds_total'} += $registo[JOB_RUNTIME_SECONDS];
	
	if(!exists($output{$key}{'seconds_max'})) {
		$output{$key}{'seconds_max'}=0;
	}
	
	if(!exists($output{$key}{'seconds_min'})) {
		$output{$key}{'seconds_min'} = $registo[JOB_RUNTIME_SECONDS] ;
	}
	
	if($output{$key}{'seconds_max'} < $registo[JOB_RUNTIME_SECONDS]) {
		$output{$key}{'seconds_max'} = $registo[JOB_RUNTIME_SECONDS] ;
	}
	
	if($output{$key}{'seconds_min'} > $registo[JOB_RUNTIME_SECONDS]) {
		$output{$key}{'seconds_min'} = $registo[JOB_RUNTIME_SECONDS] ;
	}
		
		
	#SUMS
	
	$key = $filter_date .';'. $job_date .';'. $registo[DOMAIN];	
	$sums{$key}{'job_runs'} += 1;
	$sums{$key}{'seconds_total'} += $registo[JOB_RUNTIME_SECONDS];
}

close $fp;

if(!-e $ficheiro) {
	open $fp,'>:unix', $ficheiro or die "ERROR $!\n";	
	printf($fp "%s\n",$0);
	printf($fp "LOG_DATE;JOB_DATE;DOMAIN;JOB_NAME;JOB_RUNS;SECONDS_MIN;");
	printf($fp "SECONDS_MAX;SECONDS_TOTAL\n");
} else {
	open $fp,'>>:unix', $ficheiro or die "ERROR $!\n";
}

foreach(sort keys %output) {
			
	$out_lines++;
		
	printf($fp "%s;%s;%d;%d;%d;%d\n",
		$filter_date,
		$_,		
		$output{$_}{'job_runs'},
		$output{$_}{'seconds_min'},
		$output{$_}{'seconds_max'},
		$output{$_}{'seconds_total'}
	);
		
}

close $fp;

printf("%s ",$ficheiro);
printf("lines in: %d, lines out: %d\n",$in_lines, $out_lines);

#####$out_lines = 0;
#####
#####if(!-e $ficheiro_jobs) {
#####	open $fp,'>:unix', $ficheiro_jobs or die "ERROR $!\n";	
#####	printf($fp "%s\n",$0);
#####	printf($fp "DOMAIN;JOB_NAME\n");	
#####} else {
#####	open $fp,'>>:unix', $ficheiro_jobs or die "ERROR $!\n";
#####}
#####	
#####foreach(sort keys %jobs) {
#####			
#####	$out_lines++;
#####		
#####	printf($fp "%s;%s\n",$domain,$_);
#####		
#####}
#####
#####close $fp;
#####printf("%s ",$ficheiro_jobs);
#####printf("lines in: %d, lines out: %d\n",$in_lines, $out_lines);

$out_lines = 0;

if(!-e $ficheiro_sums) {
	open $fp,'>:unix', $ficheiro_sums or die "ERROR $!\n";	
	printf($fp "%s\n",$0);
	printf($fp "LOG_DATE;JOB_DATE;DOMAIN;JOB_RUNS;SECONDS_TOTAL\n");
} else {
	open $fp,'>>:unix', $ficheiro_sums or die "ERROR $!\n";
}

foreach(sort keys %sums) {
			
	$out_lines++;
		
	printf($fp "%s;%d;%d\n",
		$_,		
		$sums{$_}{'job_runs'},
		$sums{$_}{'seconds_total'}
	);
		
}

close $fp;

printf("%s ",$ficheiro_sums);
printf("lines in: %d, lines out: %d\n",$in_lines, $out_lines);
