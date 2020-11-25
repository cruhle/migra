#TUXJES_STARTED_ENDED_ALL_IN_1.pl

#REGISTO DO FICHEIRO DE LOG
use constant	SERVER			=>	0;
use constant	DOMAIN			=>	1;
use constant	DATA_HORA		=>	2;
use constant	JOB_NUMBER		=>	3;
use constant	JOB_NAME		=>	4;
use constant	JOB_STATUS		=>	6;
use constant	RETURN_CODE		=>	7;
use constant	CLASS			=>	9;

use strict;
use warnings;
use integer;

use File::Basename;

use lib 'lib';
require DateCalcFunctions;
require date_range_6d;

my @registo;

my @ficheiros_de_input = @ARGV or die "ERROR-> Missing log files to process.\n";

my $parm;

foreach(@ficheiros_de_input) {
	$parm = $_;
	if(!-e $parm) {
		print "Ficheiro [$parm] nao encontrado!\nProcesso cancelado!\n";
		exit;
	} else {
		print "Ficheiro [$parm] validado!\n";
	}

}

my $ficheiro = basename($parm);
$ficheiro =~ /(\d+)/;
$ficheiro = date_range_6d::getDateRange($1);
$ficheiro = '/tmp/pkis/started_ended_'. $ficheiro .'.csv';

open my $fpout,'>:unix', $ficheiro or die "ERROR $!\n";
printf($fpout "%s\n",$0);
printf($fpout "SERVER;JOB_NUMBER;JOB_NAME;DOMAIN;CLASS;PART_OF_DAY;STARTED;ENDED;RUNTIME_SECONDS;RETURN_CODE\n");

my $runtime = 0;
my $fp;
my $domain;

my %jobs;

foreach(@ficheiros_de_input) {

	undef %jobs;
	
	$parm = $_;
	
	printf("Reading file [%s].\n",$parm);

	open $fp,'<',$parm or die "ERROR $!\n";
	
	while(<$fp>) {
	
		next if(length $_ < 20);
		
		chomp;
		
		next if($_ !~ /(STARTED|ENDED)/);
		@registo = split(/\t/);					
			
		$registo[DOMAIN] =~ s/BATCHPRD_//;	
		
		$domain = $registo[DOMAIN];
		
		$jobs{$registo[JOB_NUMBER]}{$registo[JOB_STATUS]} = $registo[DATA_HORA];
		$jobs{$registo[JOB_NUMBER]}{'SERVER'} = $registo[SERVER];
		$jobs{$registo[JOB_NUMBER]}{'DOMAIN'} = $registo[DOMAIN];
		$jobs{$registo[JOB_NUMBER]}{'JOB_NAME'} = $registo[JOB_NAME];
		
		if($registo[JOB_STATUS] eq 'STARTED') {
			$jobs{$registo[JOB_NUMBER]}{'CLASS'} = $registo[CLASS];
		}
		
		if($registo[JOB_STATUS] eq 'ENDED') {
			$jobs{$registo[JOB_NUMBER]}{'RETURN_CODE'} = $registo[RETURN_CODE];
		}
	}
	
	close $fp;
	
	foreach(sort keys %jobs) {
		
		if(!exists($jobs{$_}{'STARTED'})) {
			next;
		}
		
		if(!exists($jobs{$_}{'ENDED'})) {
			next;
		}		
		
		$runtime = DateCalcFunctions::get_seconds_work_time(
				$jobs{$_}{'STARTED'} , $jobs{$_}{'ENDED'} );
		
		printf($fpout "%s;%s;%s;%s;%s;%d;%s;%s;%d;%s\n",
			$jobs{$_}{'SERVER'},
			$_,
			$jobs{$_}{'JOB_NAME'},
			$jobs{$_}{'DOMAIN'},
			$jobs{$_}{'CLASS'},
			in_what_part_of_day($jobs{$_}{'STARTED'}),
			date_range_6d::showToDate($jobs{$_}{'STARTED'}),
			date_range_6d::showToDate($jobs{$_}{'ENDED'}),
			$runtime,
			$jobs{$_}{'RETURN_CODE'}
		);
		
	}
}

close $fpout;

printf("Ficheiro [%s] criado.\n",$ficheiro);


sub in_what_part_of_day {

	my $tmp = shift;
	$tmp =~ /\d{8} (\d{2})/;
	$tmp = int($1/6+1);
	return $tmp;

}