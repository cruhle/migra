#TUXJES_PANDAS_BREAK_BY_HOUR.pl

use strict;
use warnings;

use Time::Piece;
use Time::Seconds;

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

my $out_file='/tmp/pkis/XX.csv';
my $domain='-1';

#dione	BATCHPRD_RP	20190625 16:00:19	01195329	PTARARAF	-	STARTED	-	CLASS	P	SYS	dione	1_45	50593974	START
#dione	BATCHPRD_RP	20190625 23:12:37	01195329	PTARARAF	-	ENDED	C0000

open my $fp,'<',$ficheiro_entrada or die "ERROR $!\n";
while(<$fp>) {
	chomp;
	@registo = split(/\t/);
	next if(@registo<7);
	next if($registo[JOB_STATUS] !~ /(STARTED|ENDED)/);
	
	if($domain eq '-1') {
		$registo[DOMAIN] =~ s/BATCHPRD_//;	
		$domain = $registo[DOMAIN];
	}
	
	$output{$registo[JOB_NUMBER]}{'DOMAIN'} = $registo[DOMAIN];
	$output{$registo[JOB_NUMBER]}{'JOB_NAME'} = $registo[JOB_NAME];
	$output{$registo[JOB_NUMBER]}{'RUNTIME'} = 0;
	
	if($registo[JOB_STATUS] eq 'STARTED') {
		$output{$registo[JOB_NUMBER]}{'STARTED'} = $registo[DATA_HORA];
	} else {
		$output{$registo[JOB_NUMBER]}{'ENDED'} = $registo[DATA_HORA];
		$output{$registo[JOB_NUMBER]}{'RETURN_CODE'} = $registo[RETURN_CODE];
	}
	
	
}
close $fp;

$out_file =~ s/XX/$domain/;
open $fp,'>',$out_file or die "ERROR $!\n";

printf($fp "%s;%s;%s;%s;%s;%s\n",
	'DOMAIN',
	'JOB_NAME',
	'STARTED_DATE',
	'STARTED_HOUR',		
	'RUNTIME_SECONDS',
	'RETURN_CODE'		
);


foreach(sort keys %output) {

	if(!exists($output{$_}{'STARTED'})) {
		next;
	} 
	if(!exists($output{$_}{'ENDED'})) {
		next;
	} 
	
	$output{$_}{'RUNTIME'} = 
		getJobTimeInSeconds($output{$_}{'STARTED'}, $output{$_}{'ENDED'});
		
	$output{$_}{'STARTED'} = showToDate($output{$_}{'STARTED'});
	
	if(!exists($output{$_}{'RETURN_CODE'})) {
		$output{$_}{'RETURN_CODE'} = '';
	}
	
	printf($fp "%s;%s;%s;%d;%s\n",
		$domain,
		$output{$_}{'JOB_NAME'},
		$output{$_}{'STARTED'},
		$output{$_}{'RUNTIME'},		
		$output{$_}{'RETURN_CODE'}		
	);

}
close $fp;

printf("Created: %s\n",$out_file);

sub showToDate {

	my $x = shift;	

	$x =~ /(\d{4})(\d{2})(\d{2}) (\d{2})(.{6})/;

	return (sprintf("%04d-%02d-%02d;%02d" ,$1, $2, $3, $4));

}

sub getJobTimeInSeconds {

	my ($t_start, $t_end) = @_;
	
	my $t_s = Time::Piece->strptime($t_start,"%Y%m%d %H:%M:%S");
	my $t_e = Time::Piece->strptime($t_end,"%Y%m%d %H:%M:%S");
	
	return ($t_e->epoch - $t_s->epoch);

}