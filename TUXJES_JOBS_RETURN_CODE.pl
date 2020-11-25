#TUXJES_JOBS_RETURN_CODE.pl

use strict;
use warnings;
use integer;

use File::Basename;
use Date::Calc qw(Add_Delta_Days);

use lib 'lib';
require DateCalcFunctions;
require tuxjes_record_format;

my @registo;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my $ficheiro = basename($parm);
$ficheiro =~ /(\d+)/;
my $data_in_file_name = converteData($1);
#$data_in_file_name = getDateRange($data_in_file_name);

$ficheiro = '/tmp/pkis/jobs_return_codes_XX_'. $1 .'.csv';

my $fp;
my $domain;
my $key;

my %jobs;

open $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	
	next if($_ !~ /(STARTED|ENDED)/);
	@registo = split(/\t/);					
	
	$registo[tuxjes_record_format->TUXJES_DOMAIN] =~ s/BATCHPRD_//;	
	
	$domain = $registo[tuxjes_record_format->TUXJES_DOMAIN];
	
	$jobs{$registo[tuxjes_record_format->TUXJES_JOB_NUMBER]}{$registo[tuxjes_record_format->TUXJES_JOB_STATUS]} = $registo[tuxjes_record_format->TUXJES_DATA_HORA];
	$jobs{$registo[tuxjes_record_format->TUXJES_JOB_NUMBER]}{'SERVER'} = $registo[tuxjes_record_format->TUXJES_SERVER];
	$jobs{$registo[tuxjes_record_format->TUXJES_JOB_NUMBER]}{'DOMAIN'} = $registo[tuxjes_record_format->TUXJES_DOMAIN];
	$jobs{$registo[tuxjes_record_format->TUXJES_JOB_NUMBER]}{'JOB_NAME'} = $registo[tuxjes_record_format->TUXJES_JOB_NAME];
		
	if($registo[tuxjes_record_format->TUXJES_JOB_STATUS] eq 'ENDED') {
		$jobs{$registo[tuxjes_record_format->TUXJES_JOB_NUMBER]}{'RETURN_CODE'} = $registo[tuxjes_record_format->TUXJES_RETURN_CODE];
	}
}

close $fp;

$ficheiro =~ s/XX/$domain/g;

my $seconds = 0;

my %sum_jobs;

foreach(sort keys %jobs) {
	
	if(!exists($jobs{$_}{'STARTED'})) {
		next;
	}
	
	if(!exists($jobs{$_}{'ENDED'})) {
		next;
	}		
	
	$seconds = DateCalcFunctions::get_seconds_work_time(
		$jobs{$_}{'STARTED'} , $jobs{$_}{'ENDED'} 
		);
		
	$key = 	$jobs{$_}{'DOMAIN'} . ';' .
			$jobs{$_}{'JOB_NAME'} . ';' .
			$jobs{$_}{'RETURN_CODE'};

	$sum_jobs{$key}{'JOB_RUNS'} += 1;
	$sum_jobs{$key}{'JOB_RUN_SECONDS'} += $seconds;
		

}

open $fp,'>:unix', $ficheiro or die "ERROR $!\n";
printf($fp "%s\n",$0);
printf($fp "DATA;DOMAIN;JOB_NAME;RETURN_CODE;JOB_RUNS;JOB_RUN_SECONDS\n");
foreach(sort keys %sum_jobs) {
	printf($fp "%s;%s;%d;%d\n",
		$data_in_file_name,
		$_,
		$sum_jobs{$_}{'JOB_RUNS'},
		$sum_jobs{$_}{'JOB_RUN_SECONDS'}
	);
}

#	printf($fp "DOMAIN;JOB_NAME;JOB_RUNS;JOB_RUN_SECONDS;RETURN_CODE\n");
#	foreach(sort keys %sum_jobs) {
#		printf($fp "%s;%s;%d;%d;%s\n",
#			(split(/;/,$_))[0],
#			(split(/;/,$_))[1],
#			$sum_jobs{$_}{'JOB_RUNS'},
#			$sum_jobs{$_}{'JOB_RUN_SECONDS'},
#			(split(/;/,$_))[2],
#		);
#	}

close $fp;

printf("%s\n",$ficheiro);

#-----------------------------------------------

sub converteData {

	my $tmp = shift;
	$tmp =~ /(\d{2})(\d{2})(\d{2})/;
	
	return sprintf("%04d-%02d-%02d",(2000+$3),$1,$2);
	
}

sub getDateRange {

	my $data=shift;
	
	my ($ano,$mes,$dia) = split(/-/,$data);
	
	my $ret = sprintf("%04d-%02d-%02d",$ano, $mes, $dia);
	($ano, $mes, $dia) = Add_Delta_Days($ano, $mes, $dia, 6);
	
	$ret .= ';' . sprintf("%04d-%02d-%02d",$ano, $mes, $dia);
	return $ret;
	
}



