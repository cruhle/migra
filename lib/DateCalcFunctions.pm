package DateCalcFunctions;

use strict;
use warnings;
use Time::Piece;
use Time::Seconds;
use Date::Calc qw(Day_of_Week);

sub getWeekday {

	my ($y, $m, $d) = @_;
	return Day_of_Week($y, $m, $d);
	
}

sub converteData2PowerBI {

	my $z = shift;

	$z =~ /(\d{4})(\d{2})(\d{2}) (.{8})/;

	return (sprintf("%04d-%02d-%02d %s", $1, $2, $3, $4));
}

sub getYesterday {

	my ($y, $m, $d) = @_;
	my $date = sprintf("%4d-%02d-%02d",$y, $m, $d);
	$date = Time::Piece->strptime($date, "%Y-%m-%d"); 
	$date -=  ONE_DAY ;
	return sprintf("%4d%02d%02d",($date->_year) + 1900, $date->mon, $date->mday);
}

sub getYesterdayYYYYMMDD {

	my ($data) = @_;
	my $date = Time::Piece->strptime($data, "%Y%m%d"); 
	$date -=  ONE_DAY ;
	return sprintf("%4d%02d%02d",($date->_year) + 1900, $date->mon, $date->mday);
}

sub getYesterdayYYYY_MM_DD {

	my ($data) = @_;
	my $date = Time::Piece->strptime($data, "%Y-%m-%d"); 
	$date -=  ONE_DAY ;
	return sprintf("%4d%02d%02d",($date->_year) + 1900, $date->mon, $date->mday);
}

sub get_seconds_work_time {

	my ($t_start, $t_end) = @_;
	
	my $t_s = Time::Piece->strptime($t_start,"%Y%m%d %H:%M:%S");
	my $t_e = Time::Piece->strptime($t_end,"%Y%m%d %H:%M:%S");
	
	return ($t_e->epoch - $t_s->epoch);

}

sub get_total_work_time {

	my ($t_start, $t_end) = @_;
	
	my $t_s = Time::Piece->strptime($t_start,"%Y%m%d %H:%M:%S");
	my $t_e = Time::Piece->strptime($t_end,"%Y%m%d %H:%M:%S");
	
	return seconds_2_time(($t_e->epoch - $t_s->epoch));

}

sub time_2_seconds {

	my $in = shift;	
		
	#my $h = substr($in,0,2);
	#my $m = substr($in,3,2);
	#my $s = substr($in,6,2);
	
	my ($h, $m, $s) = split(/:/,$in);
	return (($h*3600)+($m*60)+$s);
	
}

sub seconds_2_time {

	my $in = shift;	
	return (sprintf("%02d:%02d:%02d", $in/3600, $in/60%60, $in%60));
	
}

sub seconds_2_hh_mm {

	my $in = shift;
	$in = seconds_2_time($in);	
	return substr($in,0,5);
	
}

sub seconds_2_hh_mm_str {

	my $in = shift;
	#$in = seconds_2_time($in);	
	#return substr($in,0,5);
	return (sprintf("%02dH%02dM", $in/3600, $in/60%60));
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

sub muda_espaco_data_hora {

	my $in = shift;	
	
	$in =~ s/\s/;/;
	
	return $in;
}

sub getLocaltime {

	my ($sec, $min, $hou, $day, $mon, $yea) = (localtime())[0..6];

	$mon++;
	$yea+=1900;
	return sprintf("%04d-%02d-%02d %02d:%02d:%02d",$yea, $mon, $day, $hou, $min, $sec);
	
}	

sub getCurrentDate {

	my ($day, $mon, $yea) = (localtime())[3..6];

	$mon++;
	$yea+=1900;
	return sprintf("%04d-%02d-%02d",$yea, $mon, $day);
	
}

sub getCurrentDateYYYYMMDD {

	my ($day, $mon, $yea) = (localtime())[3..6];

	$mon++;
	$yea+=1900;
	return sprintf("%04d%02d%02d",$yea, $mon, $day);
	
}

sub getCurrentHourHH {

	my ($hora) = (localtime())[2];

	return sprintf("%02d", $hora);
	
}	

sub getCurrenttime {

	my ($sec, $min, $hou) = (localtime())[0..2];

	return sprintf("%02d:%02d:%02d", $hou, $min, $sec);
	
}	

sub data_hora {

	my $in = shift;
	
	my ($d , $h) = split(/\s/,$in);	
	
	return (
		substr($d,0,4)
		.'-'.
		substr($d,4,2)
		.'-'.
		substr($d,6,2)
		.'_'.
		$h
	);
	
	
}


1;