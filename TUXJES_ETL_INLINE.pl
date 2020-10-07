#TUXJES_ETL_INLINE.pl

#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog
#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT_BCK/01318783.bak

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
use File::Basename;


my @ins;
my $start_time=0;
my $end_time=0;
my $work;

my $code;

#my $area = 'CO';
#my $parm = shift || die "ERROR NO INPUT FILE SUPLIED.\n";

my ($area, $parm) = @ARGV;

if(!-e $parm) {
	printf("FILE [%s] NOT FOUND.\n",$parm);
	exit ;
}

my $filename = basename($parm);

$filename =~ s/log/$area/;
$filename =~ s/\./_/g;
$filename.='_ins.csv';

$filename = '/tmp/pkis/'. $filename;

print $parm,"\n",$filename,"\n" if (DEBUG);

open my $fp,'<',$parm or die "ERROR $!\n";
open my $fpo,'>',$filename or die "ERROR $!\n";
printf($fpo "%s\n",$0);

my $linhas=0;

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@ins = split(/\t/);
		
	next if(scalar @ins != 12);
	next if($ins[STEP_NAME] eq '-');
			
			
	if(length($ins[START_TIME])==9 and length($ins[END_TIME])==9) {			
		$start_time = time_2_seconds(substr($ins[START_TIME],1));
		$end_time = time_2_seconds(substr($ins[END_TIME],1));
		$work = valida_tempos($start_time, $end_time);
	} else {
		$start_time = -1;
	    $end_time = -1;
		$work = -1;	
	}
	
	printf($fpo "%s;%s;%s;%s;%s;%d;%s\n",
		data_hora_DATA($ins[DATA_HORA]),
		$area,
		$ins[JOB_NUMBER],
		$ins[JOB_NAME],
		$ins[STEP_NAME],
		$work,
		$ins[RETURN_CODE]
		);	
	$linhas++;
}
close $fpo;
close $fp;

printf("Ficheiro [%s] criado: [%d].\n", $filename, $linhas);


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
		.' '.
		$h
	);
	
	
}

sub data_hora_DATA {

	my $in = shift;
	
	my ($d , $h) = split(/\s/,$in);	
	
	return (
		substr($d,0,4)
		.'-'.
		substr($d,4,2)
		.'-'.
		substr($d,6,2)		
	);
	
	
}

sub data_hora_HORA {

	my $in = shift;
	
	my ($d , $h) = split(/\s/,$in);	
	
	return $h ;
	
	
}

sub time_2_seconds {

	my $in = shift;
	
	my ($h, $m, $s) = split(/:/,$in);
			
	return (($h*3600)+($m*60)+$s);
	
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


