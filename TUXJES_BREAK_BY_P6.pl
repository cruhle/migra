#TUXJES_BREAK_BY_P6.pl

use strict;
use warnings;

#use Time::Piece;
#use Time::Seconds;

#REGISTO DO FICHEIRO DE LOG
use constant	SERVER			=>	0;
use constant	DOMAIN			=>	1;
use constant	DATA_HORA		=>	2;
use constant	JOB_NUMBER		=>	3;
use constant	JOB_NAME		=>	4;
use constant	JOB_STATUS		=>	6;
use constant	RETURN_CODE		=>	7;
use constant	CLASS			=>	9;

my $ficheiro_entrada = shift || die "Input file is missing.\n";

my @registo;
my %output;

#dione	BATCHPRD_RP	20190625 16:00:19	01195329	PTARARAF	-	STARTED	-	CLASS	P	SYS	dione	1_45	50593974	START
#dione	BATCHPRD_RP	20190625 23:12:37	01195329	PTARARAF	-	ENDED	C0000

open my $fp,'<',$ficheiro_entrada or die "ERROR $!\n";
while(<$fp>) {
	chomp;
	@registo = split(/\t/);
	next if(@registo<7);
	next if($registo[JOB_STATUS] !~ /(STARTED|ENDED)/);
	
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	
	$output{$registo[JOB_NUMBER]}{'DOMAIN'} = $registo[DOMAIN];
	$output{$registo[JOB_NUMBER]}{'JOB_NAME'} = $registo[JOB_NAME];
	
	if($registo[JOB_STATUS] eq 'STARTED') {
		$output{$registo[JOB_NUMBER]}{'STARTED'} = $registo[DATA_HORA];
	} else {
		$output{$registo[JOB_NUMBER]}{'ENDED'} = $registo[DATA_HORA];
		$output{$registo[JOB_NUMBER]}{'RETURN_CODE'} = $registo[RETURN_CODE];
	}
	
	
}
close $fp;

	printf("%s;%s;%s;%s;%s;%s;%s;%s\n",
		'DOMAIN',
		'JOB_NAME',
		'JOB_NUMBER',
		'START_DATE',
		'START_TIME',		
		'END_DATE',
		'END_TIME',		
		'RETURN_CODE'		
	);


foreach(sort keys %output) {

	if(!exists($output{$_}{'STARTED'})) {
		$output{$_}{'STARTED'} = '';
	} else {
		$output{$_}{'STARTED'} = showToDate($output{$_}{'STARTED'});
	}
	if(!exists($output{$_}{'ENDED'})) {
		$output{$_}{'ENDED'} = '';
	} else {
		$output{$_}{'ENDED'} = showToDate($output{$_}{'ENDED'});
	}
	if(!exists($output{$_}{'RETURN_CODE'})) {
		$output{$_}{'RETURN_CODE'} = '';
	}
	
	printf("%s;%s;%s;%s;%s;%s\n",
		$output{$_}{'DOMAIN'},
		$output{$_}{'JOB_NAME'},
		$_,							#job number
		$output{$_}{'STARTED'},
		$output{$_}{'ENDED'},		
		$output{$_}{'RETURN_CODE'}		
#		,getJobTimeInSeconds($output{$_}{'STARTED'}, $output{$_}{'ENDED'})
	);

}


sub showToDate {

	my $x = shift;	

	$x =~ /(\d{4})(\d{2})(\d{2}) (.{8})/;

	return (sprintf("%04d-%02d-%02d;%s" ,$1, $2, $3, $4));

}

sub getJobTimeInSeconds {

	my ($t_start, $t_end) = @_;
	
	my $t_s = Time::Piece->strptime($t_start,"%Y%m%d %H:%M:%S");
	my $t_e = Time::Piece->strptime($t_end,"%Y%m%d %H:%M:%S");
	
	return ($t_e->epoch - $t_s->epoch);

}