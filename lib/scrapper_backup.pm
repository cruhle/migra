#scrapper_backup.pm

package scrapper_backup;

use strict;
use warnings;

#on the pl file: 
#
#use lib 'lib';
#require scrapper_backup;
#my ($cy, $wday, $cyd) = ((localtime())[5..7]);
#$cy+=1900;
#if($wday ==0) DO BACKUP 0 == DOMINGO
#   scrapper_backup::create_backup_file(current_year, current_year_day)
#

sub create_backup_file {

	my ($cyear, $cyday) = @_;				
	my ($fyear, $fyday) = (-1, -1);
	
	my ($sec, $min, $hou, $day, $mon, $yea) = (localtime())[0..6];	
	my $bck_date = sprintf("_%04d%02d%02d_%02d%02d",(1900+$yea), (++$mon), $day, $hou, $min);
	
	if(-e 'conf/cntrl.info') {
		open my $fp,'<','conf/cntrl.info';
		($fyear, $fyday) = split(/\s/,<$fp>);
		close $fp;
	} 
			
	if((($cyear > $fyear) or ($cyday > $fyday)) and $hou>0) {	
		rename('conf/jobs.conf','conf/jobs.conf'.$bck_date);
		open my $fp,'>','conf/cntrl.info';
		printf($fp "%04d %03d", $cyear, $cyday);
		close $fp;
	} 
				
}

1;
