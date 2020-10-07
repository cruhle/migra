#tuxjes_current_log_running.pm
#Returns the TUXJES current log file name.
#The log rotates at every Sunday at 01:00

package tuxjes_current_log_running;

use strict;
use warnings;

use Time::Piece;
use Time::Seconds;

sub getCurrentLogName {

	my ($day, $mon, $yea, $wday) = (localtime())[3..6];	
	
	$mon++;
	$yea+=1900;
	
	my $date = sprintf("%4d-%02d-%02d",$yea, $mon, $day);
	$date = Time::Piece->strptime($date, "%Y-%m-%d"); 
	
	$date -= ( $wday * ONE_DAY );
		
	return 'jessys.log.' . sprintf("%02d%02d%02d",$date->mon,$date->mday,$date->yy);

}

1;