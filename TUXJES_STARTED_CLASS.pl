#TUXJES_STARTED_CLASS.pl

use strict;
use warnings;

#DESCRICAO DO REGISTO
use constant	SERVIDOR		=>	0;
use constant	DOMAIN			=>	1;
use constant	DATA_HORA		=>	2;
use constant	JOB_NUMBER		=>	3;
use constant	JOB_NAME		=>	4;
use constant	JOB_STATUS		=>	6;		# STARTED
use constant	CLASS			=>	9;

use File::Basename;

#chomp(my $ficheiro_input = `ls -t1 \$JESROOT/jessyslog/jessys.log.* | head -1`); 

my $ficheiro_input = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $ficheiro_input) {
	print "Ficheiro [$ficheiro_input] nao encontrado!\n";
	exit;
}

my @registo;
my $domain;

my $filename = basename($ficheiro_input);
$filename =~ /(\d+)/;
$filename = '/tmp/pkis/started_class_XX_'. $1 .'.csv';
open my $fpo,'>:unix', $filename or die "ERROR $!\n";
printf($fpo "%s\n",$0);
printf($fpo "SERVIDOR;DOMAIN;DATE;TIME;JOB_NUMBER;JOB_NAME;CLASS\n");

open my $fp,'<',$ficheiro_input or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);
	next if(scalar @registo != 15);
	
	next if($registo[JOB_STATUS] !~ /^STARTED$/);				
	
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	$domain = $registo[DOMAIN];
	
	printf($fpo "%s;%s;%s;%s;%s;%s;%s\n",
		$registo[SERVIDOR],
		$registo[DOMAIN],
		(split(/\s/,$registo[DATA_HORA]))[0],
		(split(/\s/,$registo[DATA_HORA]))[1],
		$registo[JOB_NUMBER],
		$registo[JOB_NAME],
		$registo[CLASS]
	);
	
}
close $fp;
close $fpo;

$fp = $filename;
$filename =~ s/XX/$domain/g;
rename($fp, $filename);

printf("Ficheiro criado [%s].\n",$filename);
#------------------------------------------------------



