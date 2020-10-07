#TUXJES_PURGED.pl

#REGISTO DO FICHEIRO DE LOG
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	JOB_STATUS	=>	6;

use strict;
use warnings;
use integer;

my @registo;

my $parm;
my $fp;
my $linha;

while(<DATA>) {

	chomp;
	$parm = $_;
	
	open $fp,'<',$parm or die "ERROR $!\n";
	printf("Reading %s ....\n",$parm);
	
	while(<$fp>) {
	
		next if(length $_ < 20);
		
		chomp;
		
		next if($_ !~ /(SUBMITTED|AUTOPURGED|STARTED|ENDED)/);
		@registo = split(/\t/);					
			
		$registo[DOMAIN] =~ s/BATCHPRD_//;	
		
		$linha = $registo[DATA_HORA] .';'. $registo[JOB_STATUS];
		
		printf("%s;%s;%s;%s;%s\n",
			$registo[DATA_HORA],
			$registo[DOMAIN],
			$registo[JOB_NUMBER],
			$registo[JOB_NAME],
			$registo[JOB_STATUS]
			
		);
	}
	
	close $fp;

}	


__DATA__
/M_I_G_R_A/AT/jes_sys_log/CO/2019/jessys.log.100619