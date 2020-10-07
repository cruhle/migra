#scrapper_library.pm

package scrapper_library;

use strict;
use warnings;

sub get_data_AAAAMM {

	my ($mon, $yea) = (localtime())[4,5];	
	$mon+=1;
	$yea+=1900;
	my $dt = sprintf("%04d%02d",$yea, $mon);
	
	return $dt;
}

1;
