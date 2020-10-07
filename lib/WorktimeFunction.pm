package WorktimeFunction;

use strict;
use warnings;
use Time::Piece;

sub getWorkTimeInSeconds {

	my ($t_sta, $t_end) = @_;
	
	my $t_s = Time::Piece->strptime($t_sta,"%Y%m%d %H:%M:%S");
	my $t_e = Time::Piece->strptime($t_end,"%Y%m%d %H:%M:%S");
	
	return ($t_e->epoch - $t_s->epoch);

}


1;