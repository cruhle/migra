#TUXJES_CREATE_WEEK_DATA

use strict;
use warnings;

use Time::Piece;
use Time::Seconds;
use Time::Local;
use POSIX qw(strftime);

my ($day, $month, $year) = (localtime())[3..5];
$year += 1900;
$month = 1;
$day = 1;

my $ANO_CNTRL = $year;

my ($epoch, $week) = (0,0);
my $date = sprintf("%4d-%02d-%02d",$year, $month, $day);
$date = Time::Piece->strptime($date, "%Y-%m-%d"); 

my $file_name = '/tmp/pkis/weeks_' . $ANO_CNTRL . '.csv';
open my $fp,'>',$file_name or die "ERROR $!\n";

printf($fp "year;date;week_number\n");
while($ANO_CNTRL == $year) {
			
	$epoch = timelocal( 0, 0, 0, $day, $month - 1, $year - 1900 );
	$week  = strftime( "%U", localtime( $epoch ) );
	
	printf($fp "%04d;%s;%02d\n",
		$date->strftime("%Y"),
		$date->strftime("%Y-%m-%d"),
		$week
	);
	
	$date = sprintf("%4d-%02d-%02d",$year, $month, $day);
	$date = Time::Piece->strptime($date, "%Y-%m-%d"); 
	$date += ONE_DAY;
	
	$year = $date->strftime("%Y");
	$month =  $date->strftime("%m");
	$day =  $date->strftime("%d");
	
	$date = sprintf("%4d-%02d-%02d",$year, $month, $day);
	$date = Time::Piece->strptime($date, "%Y-%m-%d"); 		

}

close $fp;
printf("Created file: %s\n",$file_name);


