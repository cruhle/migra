#TUXJES_BROOM.pl

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

if($filtro ne '-1') {
	if($filtro !~ /^[A-Z0-9]{6,8}$/) {
		printf("JOBNAME: 6 a 8 LETRAS e/ou NUMEROS!\n");
		printf("JOBNAME: [%s] NAO ACEITE.\nPROGRAMA A TERMINAR.\n",$filtro);
		exit;
	}
} else {
	printf("JOBNAME: 6 a 8 LETRAS e/ou NUMEROS!\n");	
	exit;
}


chomp(my @lista = `ls -tr1 \$JESROOT/jessyslog/jessys.log.*`);

my @ins;
my $data_ficheiro;
my $key;
my %hash;
my $fp;
my $linhas;

#soh do ano corrente!
my $cyear = ((localtime())[5]);
$cyear-=100;

foreach my $linhas(@lista) {

	next if($linhas !~ /$cyear$/);

	printf("A processar: [%s]\n",$linhas);
	
	open $fp,'<',$linhas or die "ERROR $!\n";			
	while(<$fp>) {
		
		chomp;
		@ins = split(/\t/);
		next if(scalar @ins != 12);
		
		$data_ficheiro = (split(/\s/,$ins[DATA_HORA]))[0];	
						
		if(index($ins[JOB_NAME], $filtro)<0) { next; }
				
		$key = $data_ficheiro . ' - ' . $ins[JOB_NUMBER] . ' - ' . $ins[JOB_NAME];
			
		if(exists($hash{$key})) {
			$hash{$key}{'steps'} .= ' ' . $ins[STEP_NAME] . '-' . $ins[RETURN_CODE];		
			$hash{$key}{'work'}  += valida_tempos(
							time_2_seconds(substr($ins[START_TIME],1)), 
							time_2_seconds(substr($ins[END_TIME],1)));
		} else {
			$hash{$key} = {		
				'steps' => $ins[STEP_NAME] . '-' . $ins[RETURN_CODE],
				'work' => valida_tempos(
							time_2_seconds(substr($ins[START_TIME],1)), 
							time_2_seconds(substr($ins[END_TIME],1)))
			};
		}
									
	}
	close $fp;

	foreach(sort keys %hash) {
		printf("%s %s [%s]\n",
			$_,
			$hash{$_}{'steps'},
			seconds_2_time($hash{$_}{'work'})
		);
	}
	
	%hash = ();
	
	print "\n";
	
}		# END FOREACH ARRAY

	
#------------------------------------------------------------------
#ROTINAS
#------------------------------------------------------------------

sub time_2_seconds {

	my $in = shift;	
	my $h = substr($in,0,2);
	my $m = substr($in,3,2);
	my $s = substr($in,6,2);
	return (($h*3600)+($m*60)+$s);
	
}

sub seconds_2_time {

	my $in = shift;	
	return (sprintf("%02d:%02d:%02d", $in/3600, $in/60%60, $in%60));
	
}

sub valida_tempos {

	my ($t1, $t2) = @_;
	my $rv = 0;
	
	if($t1 > $t2) {
		$rv = (86400-$t1) + $t2;
	} else {
		$rv = $t2 - $t1;
	}
	
	return $rv;
}


