#TUXJES_UNRAW_LTDAY_SQL.pl

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

my ($data, $parm) =  @ARGV; # || die "Usage: $0 YYYYMMDD FICHEIRO\n";

if (not defined $data) {
  die "Falta a data no formato YYYYMMDD para filtrar.\n";
}

if($data !~ /^[0-9]{8}$/) {
	die "Data errada [$data].\n";
}

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my @record;
my $data_ficheiro;

my $key;
my $pos;

my %corrida;

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {
	
	next if(length $_ < 20);
	
	next if(/AUTOPURGED	ARTJESADM|SUBMITTED	ARTJESADM/);	
			
	if(!/(STARTED|ENDED)/) {
		next;
	}
	
	$pos = $1;

	chomp;
	
	@record = split(/\t/);		

	$data_ficheiro = (split(/\s/,$record[DATA_HORA]))[0];		
	next if($data ne $data_ficheiro);	
	
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
 
print executou_quando();
 
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

sub executou_quando {

	my ($sec, $min, $hou, $day, $mon, $yea) = (localtime())[0..6];
	return (sprintf("%04d-%02d-%02d %02d:%02d:%02d", 1900+$yea, ++$mon, $day, $hou, $min, $sec));		
	
}
 
