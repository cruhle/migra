#TUXJES_pttmbcsi.pl

#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog	

#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/01647746.bak

#/PRD/EXE_COBOL/PROD/RP/tux/JESROOT/01123958

#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT


use constant	DEBUG		=>	0;

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

my $parm = shift || die "Usage: $0 FILE\n";

my @ins;
my $start_time=0;
my $end_time=0;

my ($day,$mon,$year) = (localtime())[3..6];
$year+=1900;
$mon+=1;

my $today_date= sprintf("%04d%02d%02d",$year,$mon,$day);

#printf("DATE;TIME;JOB_NUMBER;JOB_NAME;STEP_NAME;START_TIME;END_TIME;TIME;SECONDS;RETURN_CODE\n");	

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);				

	#unless(/$today_date/) {
	#	next;
	#}

	#TESTES
	#unless(/.+[TTTMBCSI|TTATTTRF]\sLATMB.+/) {
	#	next;
	#}

	#PRODUCAO
	#unless(/.+[PTTMBCSI|PTATTTRF]\sLATMB.+/) {
	unless(/.+(PTTMBCSI|PTATTTRF)\s[A-Z0-9]+.+/) {
		next;
	}
	
	#unless(/.+PTATTTRF.+LATMB.+/) {
	#	next;
	#}
	
	chomp;
	
	@ins = split(/\t/);
	next if(scalar @ins != 12);
	
	#VI	if($ins[JOB_NAME] ne 'PTTMBCSI') {
	#VI		print $ins[JOB_NAME],"\t" if(DEBUG);
	#VI		next;
	#VI	}
	#VI	
	#VI	if(substr($ins[STEP_NAME],0,5) ne 'LATMB' ) {
	#VI		print $ins[STEP_NAME],"\t",substr($ins[STEP_NAME],0,5),"\n" if (DEBUG);
	#VI		next;
	#VI	}
	
	print if (DEBUG);
	
	$start_time = time_2_seconds(substr($ins[START_TIME],1));
	$end_time = time_2_seconds(substr($ins[END_TIME],1));
	
	#job date
	#job time
	#job number
	#job name
	#step name
	#start time
	#end time
	#duration time
	#duration seconds
	#return code
		
	#printf("%s;%s;%s;%s;%s;%s;%s;%04d;%s\n",
	printf("%s;%s;%s;%-8s;%s;%04d;%s\n",
		data_hora($ins[DATA_HORA]),
		$ins[JOB_NUMBER],
		$ins[JOB_NAME],
		$ins[STEP_NAME],
	#	substr($ins[START_TIME],1),
	#	substr($ins[END_TIME],1),
		seconds_2_time(valida_tempos($start_time,$end_time)),
		valida_tempos($start_time,$end_time),
		$ins[RETURN_CODE]
		);						
		
}
close $fp;


sub data_hora {

	my $in = shift;
	
	my $d = (split(/\s/,$in))[0];
	my $h = (split(/\s/,$in))[1];	
	
	printf("[%s]\t(%s)\t(%s)\n",$in, $d, $h) if(DEBUG);
	
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
	#HH:MM:SS
	my $in = shift;
	
	my $h = substr($in,0,2);
	my $m = substr($in,3,2);
	my $s = substr($in,6,2);
	
	printf("%02d\t%02d\t%02d\n",$h,$m,$s) if (DEBUG);
	
	return (($h*3600)+($m*60)+$s);
	
}

sub seconds_2_time {
	#N...N
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