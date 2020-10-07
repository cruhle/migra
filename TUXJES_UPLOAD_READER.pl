#TUXJES_UPLOAD_READER.pl

#INPUT
#/tmp/pkis/upload_XX_.csv 
#output do tuxjes_upload.pl

use strict;
use warnings;
use integer;

use File::Basename;

#JOB_NUMBER;DOMAIN;STARTED;ENDED;RUNTIME_SECONDS;RETURN_CODE
#REGISTO DO FICHEIRO DE LOG
use constant	JOB_NUMBER			=>	0;
use constant	DOMAIN				=>	1;
use constant	STARTED				=>	2;
use constant	ENDED				=>	3;
use constant	RUNTIME_SECONDS		=>	4;
use constant	RETURN_CODE			=>	5;

my @registo;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my $ficheiro = basename($parm);
$ficheiro =~ /(\d+)/;
$ficheiro = '/tmp/pkis/reader_XX_'. $1 .'.csv';

my $fp;
my %jobs;
my $key;
my $domain;

open $fp,'<',$parm or die "ERROR $!\n";
#skip header line
<$fp>;
while(<$fp>) {

	chomp;
	@registo = split(/;/);
	
	$registo[STARTED] =~ /(\d{8})\s{1}(\d{2})/;
	$key = $registo[DOMAIN] . ';' . $1 . ';' . $2;
	$domain = $registo[DOMAIN];
	$jobs{$key}{'counter'} += 1;
	$jobs{$key}{'tempos'} += $registo[RUNTIME_SECONDS];

}
close $fp;	

$ficheiro =~ s/XX/$domain/g;

open $fp,'>:unix', $ficheiro or die "ERROR $!\n";
#printf($fp "%s\n",$0);
printf($fp "DOMAIN;JOB_DATE;JOB_HOUR;JOB_RUNS;TOTAL_RUNTIME_SECONDS\n");

foreach(sort keys %jobs) {
		
	printf($fp "%s;%s;%d;%d;%d\n",
		(split(/;/,$_))[0],			#DOMAIN
		(split(/;/,$_))[1],			#JOB_DATE
		(split(/;/,$_))[2],			#JOB_HOUR
		$jobs{$_}{'counter'},
		$jobs{$_}{'tempos'}
	);	

}

close $fp;

printf("%s\n",$ficheiro);



