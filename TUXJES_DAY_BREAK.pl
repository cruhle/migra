#TUXJES_DAY_BREAK.pl

#DESCRICAO DO REGISTO
#use constant	SERVIDOR	=>	0;
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	STEP_NAME	=>	5;
use constant	START_TIME	=>	6;
use constant	END_TIME	=>	7;

use strict;
use warnings;

my $parm = shift || die "ERROR - USAGE: $0 FILE TO READ?\n";

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my @registo;
my $data = 0;
my $break = 0;
my $fout;
my $linha;

my $ficheiro_TMPL = '/tmp/POWERBI/';
my $ficheiro='-1';

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	$linha = $_;
	
	chomp;
	@registo = split(/\t/);
	next if(scalar @registo != 12);
	
	next if($registo[STEP_NAME] eq '-');
	next if($registo[JOB_NUMBER] eq '-');
	next if(length($registo[START_TIME])!=9);
	next if(length($registo[END_TIME])!=9);
	
	$data = (split(/\s/,$registo[DATA_HORA]))[0];
	$registo[DOMAIN] =~ s/BATCHPRD_//;
	
	if($break == 0) {
		$break = $data;
		$ficheiro = getFilename($registo[DOMAIN], $break);
		open $fout,'>>',$ficheiro or die "ERROR -$!\n";
	}
	
	if($break ne $data) {
		close $fout;
		$break = $data;
		printf("%s ...\n",$ficheiro);
		$ficheiro = getFilename($registo[DOMAIN], $break);
		open $fout,'>>',$ficheiro or die "ERROR -$!\n";
	}
	
	printf( $fout "%s",$linha);
				
}

if($ficheiro ne '-1') {
	printf("%s ...\n",$ficheiro);
	close $fout;
}

close $fp;


sub getFilename {
	
	my ($domain, $data) = @_;
	
	return ($ficheiro_TMPL . $domain . '/' . $domain .'_' . $data .'.csv');
	
}
