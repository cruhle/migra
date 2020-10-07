#TUXJES_RUNTIME_TAIL.pl

use strict;
use warnings;
use integer;
use File::Basename;

use lib 'lib';
require DateCalcFunctions;

use constant	DEBUG		=>	0;

#DESCRICAO DO REGISTO
use constant	SERVIDOR	=>	0;
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;

use constant	START_TIME	=>	6;
use constant	AUTOPURGED	=>	6;
use constant	ENDED		=>	6;

use constant	END_TIME	=>	7;
use constant	ENDED_RC	=>	7;

use constant	RETURN_CODE	=>	11;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	printf("File [%s] not FOUND.\n",$parm);
	exit;
}

my $domain = $ENV{"TUXJESDOMAIN"} || '';
if($domain eq '') {
	print "ERRO falta  --> TUXJESDOMAIN <-- variavel.\n";
	exit;
}

my $filename = basename($parm);
$filename =~ /(\d+)/;
$filename = '/tmp/pkis/runtime_' . $domain .'_'. $1 .'.csv';

my @registo;
my ($key, $st, $ed, $sts, $eds) =('', '', '', 0, 0);

my %seconds;

open my $fp,'<',$parm or die "ERROR $!\n";
open my $fpo,'>',$filename or die "ERROR - write $!\n";
printf($fpo "%s\n",$0);

printf($fpo "DATA_HORA;DOMAIN;JOB_NUMBER;JOB_NAME;STEP_NAME;");
printf($fpo "STEP_START_TIME;STEP_END_TIME;STEP_START_SECONDS;STEP_END_SECONDS;RETURN_CODE\n");

while(<$fp>) {

	next if(length($_)<61);
		
	chomp;
	@registo = split(/\t/);
	$key = @registo;
	next if($key < 6);
	next if($registo[AUTOPURGED] eq 'AUTOPURGED');
			
	printf($fpo "%s;%s;%s;%s;",
		$registo[DATA_HORA],
		$domain,
		$registo[JOB_NUMBER],
		$registo[JOB_NAME]
		);
	
	if($registo[STEP_NAME] eq '-') {
		if($registo[ENDED] eq 'ENDED') {
			printf($fpo "%s;;;;;%s\n",	$registo[ENDED],$registo[ENDED_RC]);
		} else { printf($fpo "%s;;;;;;\n",$registo[ENDED]); }
	} else {
		$st = $ed = '';
		$sts = $eds = 0;
		if(length($registo[START_TIME]) == 9) {
			$st = substr($registo[START_TIME],1);
			$sts = DateCalcFunctions::time_2_seconds($st);
		}
		if(length($registo[END_TIME]) == 9) {
			$ed = substr($registo[END_TIME],1);
			$eds = DateCalcFunctions::time_2_seconds($ed);
		}
		printf($fpo "%s;%s;%s;%d;%d;%s\n",
			$registo[STEP_NAME],
			$st,
			$ed,
			$sts,
			$eds,
			$registo[RETURN_CODE]
			);
	}
	
		
}
close $fp;
close $fpo;

printf("Ficheiro [%s] criado.\n",$filename);

#---------------rotinas

sub hashCallTime2Seconds {

	my $time = shift;
	
	if(exists($seconds{$time})) {
		return $seconds{$time};
	} else {
		my $tmp = DateCalcFunctions::time_2_seconds($time);
		$seconds{$time} = $tmp;
		return $tmp;
		
	}

}

