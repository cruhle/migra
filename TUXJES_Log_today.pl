#TUXJES_Log_today.pl

use strict;
use warnings;
use integer;

#/PRD/EXE_COBOL/PROD/FO/tux/JESROOT/jessyslog
#/DEV/EXE_COBOL/DEV/FO/tux/JESROOT

#DESCRICAO DO REGISTO
use constant	SERVIDOR		=>	0;
use constant	CALLED_FROM		=>	1;
use constant	DATA_HORA		=>	2;
use constant	JOB_NUMBER		=>	3;
use constant	JOB_NAME		=>	4;
use constant	STEP_NAME		=>	5;
use constant	START_TIME		=>	6;
use constant	END_TIME		=>	7;
use constant	RETURN_CODE		=>	11;

use constant	REJECT_C0000	=>	1;

my $parm = shift || die "Usage: $0 FILE\n";

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my @ins;
my $data;
my $hora;

my $time_start;
my $time_end;

my ($day,$mon,$year) = (localtime())[3..6];
$year+=1900;
$mon+=1;

my $today_date= sprintf("%04d%02d%02d",$year,$mon,$day);

#work around for another date :-)
#$today_date='20190508';

my $fileout = cria_nome_ficheiro($today_date);

open my $fp,'<',$parm or die "ERROR $!\n";
open my $fpo,'>',$fileout or die "ERROR $!\n";
printf($fpo "%s\n",$0);

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@ins = split(/\t/);
		
	next if(scalar @ins != 12);
		
	($data, $hora) = split(/\s/,$ins[DATA_HORA]);
	
	next if($data ne $today_date);
	
	if(REJECT_C0000) {
		next if(
				substr($ins[START_TIME],1) eq substr($ins[END_TIME],1)
				and $ins[RETURN_CODE] eq 'C0000'
			   );
	}

#pretty screen view format
# imprime so o tempo de processamento hh:mm:ss	
printf($fpo "%s\t%s\t%-15s\t%-20s\t%s\t%s\n",	
	$hora,
	$ins[JOB_NUMBER],
	$ins[JOB_NAME], 
	$ins[STEP_NAME],
	
	seconds_2_time(
		valida_tempos(
			time_2_seconds(substr($ins[START_TIME],1)),
			time_2_seconds(substr($ins[END_TIME],1))
		)
	),
	
	$ins[RETURN_CODE]
);

	
## imprime so o tempo de processamento hh:mm:ss	
#printf($fpo "%s;%s;%s;%s;%s;%s\n",	
#	$hora,
#	$ins[JOB_NUMBER],
#	$ins[JOB_NAME], 
#	$ins[STEP_NAME],
#	
#	seconds_2_time(
#		valida_tempos(
#			time_2_seconds(substr($ins[START_TIME],1)),
#			time_2_seconds(substr($ins[END_TIME],1))
#		)
#	),
#	
#	$ins[RETURN_CODE]
#);

	
## hh:mm:ss	
#printf($fpo "%s;%s;%s;%s;%s;%s;%s\n",	
#	$hora,
#	$ins[JOB_NUMBER],
#	$ins[JOB_NAME], 
#	$ins[STEP_NAME],
#	substr($ins[START_TIME],1),
#	substr($ins[END_TIME],1),
#	$ins[RETURN_CODE]
#);
	

##em segundos
#printf($fpo "%05d;%s;%s;%s;%05d;%05d;%s\n",
#	time_2_seconds($hora),
#	$ins[JOB_NUMBER],
#	$ins[JOB_NAME], 
#	$ins[STEP_NAME],
#	time_2_seconds(substr($ins[START_TIME],1)),
#	time_2_seconds(substr($ins[END_TIME],1)),
#	$ins[RETURN_CODE]
#);	
	
}
close $fpo;
close $fp;
printf("Ficheiro [%s] criado com sucesso.\n",$fileout);

#---------------------------------------------------------------------------------
#FUNCTIONS
#---------------------------------------------------------------------------------
sub cria_nome_ficheiro {

	my ($area) = @_;
	
	return (sprintf("FILE_%s.log",$area)); 
	
}

sub time_2_seconds {

	my ($tempo) = @_;
	
	my ($h, $m, $s) = split(/:/,$tempo);
	
	return (($h*3600)+($m*60)+$s);
	
}

sub seconds_2_time {

	my $segundos = shift;
	
	return (sprintf("%02d:%02d:%02d", 
		$segundos/3600, 
		$segundos/60%60, 
		$segundos%60)
		);
	
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








