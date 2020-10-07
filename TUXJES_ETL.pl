#TUXJES_ETL.pl

#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog
#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT_BCK/01318783.bak

#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT

#REGISTO DO FICHEIRO DE LOG
use constant	DOMAIN		=>	1;
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
use File::Basename;

my ($parm) =  @ARGV; 

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my @registo;
my $start_time=0;
my $end_time=0;
my $work;

my $code;

#my %rcodes;

my %step_counter;

my $area = 'XX';

my $filename = basename($parm);

$filename =~ s/log/$area/;
$filename =~ s/\./_/g;
$filename.='.del';

$filename = '/tmp/pkis/'. $filename;

open my $fp,'<',$parm or die "ERROR $!\n";
open my $fpo,'>',$filename or die "ERROR $!\n";
printf($fpo "%s\n",$0);
printf($fpo "DATA;HORA;DOMAIN;JOB_NUMBER;JOB_NAME;STEP_NUMBER;STEP_NAME;TIME_SECONDS;RETURN_CODE\n");
while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);
		
	next if(scalar @registo != 12);
	next if($registo[STEP_NAME] eq '-');
			
	next if(length($registo[START_TIME])!=9);
	next if(length($registo[END_TIME])!=9);
	$start_time = time_2_seconds(substr($registo[START_TIME],1));
	$end_time = time_2_seconds(substr($registo[END_TIME],1));
	$work = valida_tempos($start_time, $end_time);
	
	#$code = $registo[RETURN_CODE];
	#$code =~ tr/0-9//cd;	
	#if($code < 5) {
	#	#if($code == 4) { print  $registo[RETURN_CODE],"\t"; }
	#	next;
	#}
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	$area = $registo[DOMAIN];		
	
	$step_counter{$registo[JOB_NUMBER]}+=1;
	
	printf($fpo "%s;%s;%s;%s;%d;%s;%d;%s\n",
		data_hora($registo[DATA_HORA]),
		$area,
		$registo[JOB_NUMBER],
		$registo[JOB_NAME],
		$step_counter{$registo[JOB_NUMBER]},
		$registo[STEP_NAME],
		valida_tempos($start_time, $end_time),
		$registo[RETURN_CODE]
		);	

#	$rcodes{$registo[RETURN_CODE]} += 1;
		
}
close $fpo;
close $fp;

$fp = $filename;
$fp =~ s/XX/$area/g;

rename($filename, $fp);

printf("Ficheiro [%s] criado.\n",$fp);

#foreach(sort keys %rcodes) {
#	printf("%10s\t%d\n",$_, $rcodes{$_});
#}

#------------------------------------------------------
#SUB-ROTINAS
#------------------------------------------------------

sub data_hora {

	my $in = shift;
	
	my ($d , $h) = split(/\s/,$in);	
	
	return (
		substr($d,0,4)
		.'-'.
		substr($d,4,2)
		.'-'.
		substr($d,6,2)
		.';'.
		$h
	);
	
	
}

sub time_2_seconds {

	my $in = shift;
	
	my ($h, $m, $s) = split(/:/,$in);
			
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


##########	# Create the data for the chart.
##########	v <- c(0003,
##########	0024,
##########	0087,
##########	0108,
##########	0002
##########	)
##########	
##########	labelsm <- c('a','b','c','d','a1')
##########	# Give the chart file a name.
##########	png(file = "line_chart.jpg")
##########	
##########	# Plot the bar chart. 
##########	plot(v,type = "o",axes=FALSE,ann=FALSE)
##########	axis(1, at=1:5, lab=c("Mon","Tue","Wed","Thu","Fri"))
##########	box()
##########	
##########	# Save the file.
##########	dev.off()
