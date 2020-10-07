package TuxjesLogDate;

use strict;
use warnings;
use Time::Piece;
use Time::Seconds;

sub getTuxjesLogDate {

	my ($day, $mon, $yea, $wday) = (localtime())[3..6];
	
	$yea+=1900;
	$mon++;

	my $date = sprintf("%4d-%02d-%02d",$yea, $mon, $day);
	$date = Time::Piece->strptime($date, "%Y-%m-%d"); 
	$date -= ( $wday * ONE_DAY );
	return sprintf("%02d%02d%2d",$date->mon,$date->mday,$date->yy);

}


1;