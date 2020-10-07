package LogScrapperFunctions;

use strict;
use warnings;

sub converteFormatoData {

	my $z = shift;

	$z =~ /(\d{4})(\d{2})(\d{2}) (.{8})/;

	return (sprintf("%04d-%02d-%02d %s", $1, $2, $3, $4));
}

sub getCurrentDateTime {

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
	#2019-12-17
}

sub getCurrentTime {

	my ($sec, $min, $hou) = (localtime())[0..2];

	return sprintf("%02d:%02d:%02d", $hou, $min, $sec);
	#12:35:35
}	

sub sendEmergencyEMAIL {

#		my($subject, $emailTO, $emailContents) = @_;

		my($emailTO, $subject, $emailContents) = @_;
		
#		my $emailTO = '--PUT EMAIL HERE TO SEND TO--';
	
#	`mailx -s '$subject' $emailTO $emailContents`;

}


1;