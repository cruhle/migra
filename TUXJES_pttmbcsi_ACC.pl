#TUXJES_pttmbcsi_ACC.pl

#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog

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

my %data;
my @ins;
my $start_time=0;
my $end_time=0;

my $key;
my $work;
my $data_hora;

open my $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	#TESTES
	#unless(/.+[TTTMBCSI|TTATTTRF]\sLATMB.+/) {
	#	next;
	#}

	#PRODUCAO
	unless(/.+[PTTMBCSI|PTATTTRF]\sLATMB.+/) {
		next;
	}
	
	#unless(/.+PTATTTRF\sLATMB.+/) {
	#	next;
	#}
	
	#unless(/.+PTTMBCSI\sLATMB.+/) {
	#	next;
	#}
	
	chomp;
	
	@ins = split(/\t/);
		
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
	
	#$key = $ins[STEP_NAME];
	$key = $ins[STEP_NAME].':'.$ins[JOB_NAME];
	
	$work = valida_tempos($start_time, $end_time);
	$data_hora = data_hora($ins[DATA_HORA]);
	
	if(exists($data{$key})) {
		
		$data{$key}{'contador'} += 1;
		$data{$key}{'total'} += $work;
		
		if($work > $data{$key}{'max'}) {
			$data{$key}{'max'} = $work;
			$data{$key}{'data'} = $data_hora;
		}					
	} else {
		$data{$key} = {		
				'contador' => 1,
				'max' => $work,
				'data' => $data_hora,
				'total' => $work
		};
	}
			
}
close $fp;

for $key (sort keys %data) {
	printf("%s;%s;%03d;%04d;%s;%05d;%04d\n",
		(split(/:/,$key))[0],
		(split(/:/,$key))[1],
		$data{$key}{'contador'}, 
		$data{$key}{'max'},
		$data{$key}{'data'},
		$data{$key}{'total'},
		$data{$key}{'total'} / $data{$key}{'contador'}
	);

}

sub data_hora {

	my $in = shift;
	
	my $d = (split(/\s/,$in))[0];
	my $h = (split(/\s/,$in))[1];	
	
	printf("[%s]\t(%s)\t(%s)\n",$in, $h,$d) if(DEBUG);
	
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
	
	my $h = substr($in,0,2);
	my $m = substr($in,3,2);
	my $s = substr($in,6,2);
	
	printf("%02d\t%02d\t%02d\n",$h,$m,$s) if (DEBUG);
	
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