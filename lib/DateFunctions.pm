package DateFunctions;

use strict;
use warnings;

sub getLocaltime() {

	my ($sec, $min, $hou, $day, $mon, $yea) = (localtime())[0..6];

	$mon++;
	$yea+=1900;
	return sprintf("%04d-%02d-%02d %02d:%02d:%02d",$yea, $mon, $day, $hou, $min, $sec);
	
}	

sub getCurrentDate() {

	my ($day, $mon, $yea) = (localtime())[3..6];

	$mon++;
	$yea+=1900;
	return sprintf("%04d-%02d-%02d",$yea, $mon, $day);
	
}

sub getCurrentDateYYYYMMDD() {

	my ($day, $mon, $yea) = (localtime())[3..6];

	$mon++;
	$yea+=1900;
	return sprintf("%04d%02d%02d",$yea, $mon, $day);
	
}

sub getCurrentHourHH() {

	my ($hora) = (localtime())[2];

	return sprintf("%02d", $hora);
	
}	

sub getCurrenttime() {

	my ($sec, $min, $hou) = (localtime())[0..2];

	return sprintf("%02d:%02d:%02d", $hou, $min, $sec);
	
}	

1;