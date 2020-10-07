#TUXJES_UNRAW.pl

use strict;
use warnings;
use File::Basename;
use Time::Piece;

#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT
#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog

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

use constant	DATA_HORA	=>	2;

my ($data, $parm) =  @ARGV; # || die "Usage: $0 YYYYMMDD FICHEIRO\n";

if (not defined $data) {
  die "Falta a data no formato YYYYMMDD para filtrar.\n";
}

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my $filename = basename($parm);
$data = uc($data);
$filename =~ s/log/$data/;
$filename =~ s/\./_/g;
$filename.='_day.csv';
$filename = '/tmp/pkis/'. $filename;

my @record;
my $data_ficheiro;
my $start_time;
my $end_time;
my $domain;
my ($start_seconds, $end_seconds, $seconds) = (0,0,0);

my $key;
my $pos;

my %corrida;
my %diario;

open my $fp,'<',$parm or die "ERROR $!\n";

open my $fpout,'>',$filename or die "ERROR $!\n";
printf($fpout "%s\n",$0);

while(<$fp>) {
	
	next if(length $_ < 20);
	
	next if(/AUTOPURGED	ARTJESADM|SUBMITTED	ARTJESADM/);	
			
	if(!/(STARTED|ENDED)/) {
		next;
	}
	
	$pos = $1;

	chomp;
	
	@record = split(/\t/);		
	
	next if($record[JOB_NUMBER] !~ /^[0-9]{8}$/);
		
	$key = $record[JOB_NUMBER] .' '. $record[JOB_NAME];
		
	
	if(exists($corrida{$key})) {
		printf($fpout "%-17s %s %s %s %s %s\n",
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
		
		$diario{(split(/\s/,$record[DATA_HORA]))[0]} += 1;
	}
	
	next;
	
	printf("%s %s %s %s\n", 
		$record[DATA_HORA],
		$record[JOB_NUMBER],
		$record[JOB_NAME],
		$pos
		);
	
	next;
	
	$data_ficheiro = (split(/\s/,$record[DATA_HORA]))[0];		
	
	next if($data ne $data_ficheiro);
	
	#print substr($record[6],1),"\t",substr($record[7],1),"\n";
	$start_time = substr($record[6],1);
	$end_time = substr($record[7],1);
	
	$start_seconds = time_2_seconds($start_time);
	$end_seconds = time_2_seconds($end_time);
	$seconds = $end_seconds-$start_seconds;
	$seconds = valida_tempos($start_seconds, $end_seconds);
	
	$domain = $record[DOMAIN];
	$domain =~ m/\_([A-Z]{2}$)/;
	$domain =  $1;
			
	#print "$start_time\t$end_time\t$start_seconds\t$end_seconds\t$seconds\n" if($start_time ne $end_time);
	#print "$start_time $end_time $start_seconds\t$end_seconds\t$seconds\n" if($seconds>59);
	printf("%s %s %s %s %s %6d %6d %6d %s\n",
			$data_ficheiro,
			$record[JOB_NUMBER],
			$domain,
			$start_time,
			$end_time,
			$start_seconds,
			$end_seconds,
			$seconds,
			seconds_2_time($seconds)
	) if($seconds>120);
	
	#print "$_\n";					
}
close $fp;
close $fpout;
printf("Ficheiro [%s] criado.\n",$filename);

$filename = '/tmp/pkis/job_counter.csv'; 

open $fpout,'>>',$filename;
foreach(sort keys %diario) {
	printf($fpout "%s %s %d\n",$_, $data, $diario{$_});
}
close $fpout;
 
printf("Ficheiro [%s] criado|actualizado.\n",$filename);
 
 
#-------------ROTINAS-------------
 

sub get_total_work_time {

	my ($t_start, $t_end) = @_;
	
	my $t_s = Time::Piece->strptime($t_start,"%Y%m%d %H:%M:%S");
	my $t_e = Time::Piece->strptime($t_end,"%Y%m%d %H:%M:%S");
	
	return seconds_2_time(($t_e->epoch - $t_s->epoch));

}

sub seconds_2_time {

	my $in = shift;	
	#return (sprintf("%02d:%02d:%02d [%6d]", $in/3600, $in/60%60, $in%60, $in));	
	return (sprintf("%02d:%02d:%02d %d", $in/3600, $in/60%60, $in%60, $in));	
}
 
 
 