#TUXJES_TODAY.pl

#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT
#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog

use constant	DEBUG		=>	0;

#DESCRICAO DO REGISTO
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
use constant	START_TIME	=>	6;
use constant	END_TIME	=>	7;
use constant	RETURN_CODE	=>	11;

use strict;
use warnings;
use integer;

my ($filtro) =  shift || '-1';
$filtro = uc($filtro);

my $parm = 'rp/jessys.log.060919';
my $data = get_data();

##if(!-e $parm) {
##	print "Ficheiro [$parm] nao encontrado!\n";
##	exit;
##}

my @registo;
my $data_ficheiro;
my $job;

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {
	
	chomp;
	@registo = split(/\t/);
	next if(scalar @registo != 12);
	
	$data_ficheiro = (split(/\s/,$registo[DATA_HORA]))[0];	

	print $data,"\t",$data_ficheiro,"\n" if(DEBUG);
		
	next if($data ne $data_ficheiro);
	
	$job = $registo[JOB_NAME];
	
	next if($filtro eq '-1' or
			(index($job, $filtro) < 0)
			);
				
	printf("%s\t%s\t%s\t%-10s\t%s\n",
		get_hora($registo[DATA_HORA]),
		$registo[JOB_NUMBER],
		$registo[JOB_NAME],
		$registo[STEP_NAME],
		$registo[RETURN_CODE]
		);
			
}
close $fp;

#------------------------------------------------------------------
#ROTINAS
#------------------------------------------------------------------

sub get_data {

	my ($day, $mon, $yea) = (localtime())[3..6];	
	$mon++;
	$yea+=1900;
	my $dt = sprintf("%04d%02d%02d",$yea, $mon, $day);
	return $dt;
}

sub get_hora {

	my $in = shift;	
	my $d = (split(/\s/,$in))[0];
	my $h = (split(/\s/,$in))[1];		
	
	return $h;
		
}



