#TUXJES_JOB_SEEKER.pl

use strict;
use warnings;

use constant	DEBUG		=>	0;
use constant	BACK_LOG_TO	=>	3;

my $jobname = shift || die "Modo de uso: $0 JOBNAME [3-8 chars].\n";

if($jobname !~ /^[a-zA-Z0-9]{3,8}$/) {
	printf("$0 (JOBNAME: LETRAS e/OU NUMEROS! MIN: 3 - MAX: 8!)\n");
	exit;
}
$jobname = uc($jobname);
my $ret=0;
my $cnt=0;
chomp(my @lista_ficheiros = `dir \\M_I_G_R_A\\AT\\jes_sys_log\\FO\\jessys.log.* /s/b /o-d `);

foreach(@lista_ficheiros) {

	#chomp;
	#
	print "\n[$_]\n";
	$ret = system ("perl TUXJES_UNRAW_JOBNAME.pl $jobname $_");
	print "\n";
	print "$_\tRCODE: $ret\n" if(DEBUG);	
	$cnt++;
	last if($cnt==BACK_LOG_TO);
}
