#TUXJES_RAW_JOBNAME.pl

use strict;
use warnings;
use Time::Piece;

#DESCRICAO DO REGISTO
use constant	SERVIDOR	=>	0;
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
use constant	START_TIME	=>	6;
use constant	END_TIME	=>	7;
use constant	RETURN_CODE	=>	11;

my $jobname = shift || die "Modo de uso: $0 JOBNAME [3-8 chars].\n";

if($jobname !~ /^[a-zA-Z0-9]{3,8}$/) {
	printf("$0 (JOBNAME: LETRAS e/OU NUMEROS! MIN: 3 - MAX: 8!)\n");
	exit;
}
$jobname = uc($jobname);

chomp(my @lista_ficheiros =  `ls -t1 \$JESROOT/jessyslog/jessys.log.* | head -3`);

#chomp(my @lista_ficheiros = `dir \\M_I_G_R_A\\AT\\jes_sys_log\\FO\\jessys.log.* /s/b /o-d `);

my @record;
my $key;
my $pos;
my %corrida;
my $ficheiro_in;

foreach(@lista_ficheiros) {

	$ficheiro_in = $_;
	
	printf("[%s]\n\n",$ficheiro_in);
	
	open my $fp,'<',$ficheiro_in or die "ERROR $!\n";

	while(<$fp>) {
	
		next if(length $_ < 20);
	
		next if(/AUTOPURGED	ARTJESADM|SUBMITTED	ARTJESADM/);	
			
		if(!/(STARTED|ENDED)/) { next; }
	
		$pos = $1;

		chomp;
	
		@record = split(/\t/);				
		
		next if($record[JOB_NAME] !~ m/$jobname/);	
		
		next if($record[JOB_NUMBER] !~ /^[0-9]{8}$/);
			
		$key = $record[JOB_NUMBER] .' '. $record[JOB_NAME];
				
		if(exists($corrida{$key})) {
			printf("%-17s %s %s %s %s %s\n",
				$key,
				$corrida{$key}{'timestamp'},
				$corrida{$key}{'step'},
				$record[DATA_HORA],
				$pos,
				get_total_work_time($corrida{$key}{'timestamp'}, $record[DATA_HORA])
			);
			delete $corrida{$key};
		} else {
			$corrida{$key} = {
				'timestamp' => $record[DATA_HORA],
				'step' => $pos
			};
			
		}
		
	}
	close $fp;

	foreach $key(sort keys %corrida) {
		printf("%-17s %s %s %s %s %s\n",
			$key,
			$corrida{$key}{'timestamp'},
			$corrida{$key}{'step'},
			"",
			"",
			""
		) if ($corrida{$key}{'step'} eq 'STARTED');
		printf("%-17s %17s %7s %s %s %s\n",
			$key,
			"",
			"",
			$corrida{$key}{'timestamp'},
			$corrida{$key}{'step'},
			""
		) if ($corrida{$key}{'step'} eq 'ENDED');
	} 

	%corrida = ();

}	
 
#-------------ROTINAS-------------
 
sub get_total_work_time {

	my ($t_start, $t_end) = @_;
	
	my $t_s = Time::Piece->strptime($t_start,"%Y%m%d %H:%M:%S");
	my $t_e = Time::Piece->strptime($t_end,"%Y%m%d %H:%M:%S");
	
	return seconds_2_time(($t_e->epoch - $t_s->epoch));

}

sub seconds_2_time {
	my $in = shift;	
	return (sprintf("%02d:%02d:%02d", $in/3600, $in/60%60, $in%60));	
}


 
