#TUXJES_GETLOG_FILE.pl

use strict;
use warnings;
use integer;

my ($job_nr) =  @ARGV; 

if (not defined $job_nr) {  die "Falta o JOBNUMBER.\n"; }

if($job_nr !~ /^[0-9]{8}$/) {
	printf("JOBNUMBER: NUMEROS! 8!\n");
	exit;
}

my @dirs;
my ($ficheiro, $tmp);

push @dirs,'/PRD/EXE_COBOL/PROD/CO/tux/JESROOT/%s/LOG/%s.log';
push @dirs,'/PRD/EXE_COBOL/PROD/CO/tux/JESROOT/%s.bak/LOG/%s.log';
push @dirs,'/PRD/EXE_COBOL/PROD/CO/tux/JESROOT_BCK/%s.bak/LOG/%s.log';

foreach $tmp(@dirs) {
	
	$ficheiro = sprintf($tmp, $job_nr, $job_nr);
	
	if(-e $ficheiro) {
	
		open my $fp,'<',$ficheiro;
		open my $fpo,'>','/tmp/tuxjes'.$job_nr;
		while($fp) {
			print $fpo $_;
		}
		close $fpo;
		close $fp;
		printf("Ficheiro [%s] criado em /tmp/tuxjes.\n", $job_nr);
		printf("Copiado de: [%s].\n",$ficheiro);
	}
	
}

#------------------------------------------------------

