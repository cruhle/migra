#TUXJES_GET_JESSYS_LOG.pl

use strict;
use warnings;

use lib 'lib';
require TuxjesLogDate;

my @dominios = qw(CO FO RP PR MISC);

my $logDate = TuxjesLogDate::getTuxjesLogDate();

my ($orign, $dest, $cmd) = ('','', '');

#/PRD/EXE_COBOL/PROD/%s1/tux/JESROOT/jessyslog/jessys.log.%s2		D:\M_I_G_R_A\%s1\jes_sys_log\%s2\

foreach my $domino(@dominios) {

	$orign = sprintf("/PRD/EXE_COBOL/PROD/%s/tux/JESROOT/jessyslog/jessys.log.%s",$domino, $logDate);
	$dest = sprintf("D:/M_I_G_R_A/AT/jes_sys_log/%s/",$domino);
	
	#printf("/PORTABLE/putty/pscp -pw cobpr cobol_pr\@tux-prd-mf.tap.pt:%s %s",$orign, $dest);
	
	printf("\n%s\n=> %s\n\n",$orign, $dest);
		
	$cmd = sprintf("/PORTABLE/putty/pscp -pw cobpr -p cobol_pr\@tux-prd-mf.tap.pt:%s %s",$orign, $dest);
	
	#printf("\n%s\n",$cmd);
	
#	system($cmd);
	
}


#\PORTABLE\putty\pscp -pw cobdv cobol_dv@tux-dev-mf.tap.pt:/DEV/EXE_COBOL/DEV/RP/tux/JESROOT/test4 D:\2019\test4

#/PRD/EXE_COBOL/PROD/MISC/tux/JESROOT/jessyslog


