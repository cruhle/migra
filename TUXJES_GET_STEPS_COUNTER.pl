#TUXJES_GET_STEPS_COUNTER.pl
#2020-09-22

use strict;
use warnings;
use integer;

#REGISTO DO FICHEIRO DE LOG
#campos por registo
use constant	SUBMIT_PURGED	=>	10;
use constant	STARTED			=>	15;
use constant	USER_STEPS		=>	12;
use constant	ENDED			=>	8;

#possicoes dos campos no registo respectivo
use constant	DOMAIN			=>	1;
use constant	STEP_NAME_6		=>	5;
use constant	STEP_NAME_7		=>	6;
use constant	RETURN_CODE		=>	11;

my ($parm) =  @ARGV; 

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my @registo;
my %steps_counter;
my $length;
my $domain = '-1';
my $return_code;
my @error_records;
my $string_record;

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);
	$length = @registo;
	
	if($domain eq '-1') {
		$registo[DOMAIN] =~ s/BATCHPRD_//;
		$domain = $registo[DOMAIN];
	}
	
	if($length == SUBMIT_PURGED) {
		$steps_counter{$registo[STEP_NAME_7]} += 1;
		next;
	}
	
	if($length == STARTED) {
		$steps_counter{$registo[STEP_NAME_7]} += 1;
		next;
	}	
	
	if($length == USER_STEPS) {
		$steps_counter{$registo[STEP_NAME_6]} += 1;
		
		$return_code = $registo[RETURN_CODE];
		if(isReturnCodeError($return_code)) {
			$string_record=$domain . ' ' . split_data($registo[2]) . ' ';
			for(my $i=3;$i<8;$i++) {
				$string_record .= $registo[$i] . ' ';
				#$string_record .= sprintf("%-12s ",$registo[$i]);
			}
			$string_record .= $return_code;
			push @error_records, $string_record;
		}
		
		next;
	}
	
	if($length == ENDED) {
		$steps_counter{$registo[STEP_NAME_7]} += 1;		
		next;
	}
}

close $fp;

foreach(sort keys %steps_counter) {
	printf("%s\t%-20s\t%5d\n",
		$domain,
		$_, 
		$steps_counter{$_}
	);
}

print "\n\n";

printf("DOMAIN JOB-DATE JOB-TIME JOB-NUMBER JOB-NAME STEP-NAME STEP-START-TIME STEP-END-TIME RETURN_CODE\n");

foreach(@error_records) {
	printf("%s\n", $_);
}

#---------------------------------------------------------------------------------------

sub isReturnCodeError {

	my $entrada = shift;
	
	return 1 if(length($entrada)<5);
	if(length($entrada)==5) {
		return 1 if(substr($entrada,1)>40 or substr($entrada,0,1) ne 'C');
	}

	return 0;
}

sub split_data {

	my $ent = shift;		
	
	$ent =~ /(\d{4})(\d{2})(\d{2}) (.{8})/;	
	$ent = sprintf("%4d-%02d-%02d %s",$1,$2,$3,$4);

	return $ent;
}



