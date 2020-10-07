#TUXJES_NOT_ZERO.pl

use strict;
use warnings;

#DESCRICAO DO REGISTO
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
use constant	START_TIME	=>	6;
use constant	END_TIME	=>	7;
use constant	RETURN_CODE	=>	11;

#my $parm = `ls -t1 \$JESROOT/jessyslog/jessys.log.* | head -1`;

my $parm = shift || die "ERROR - file to read.\n";

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my ($day, $mon, $yea) = (localtime())[3..6];	
my $todays_date = sprintf("%04d%02d%02d",(1900+$yea), (++$mon), $day);

my @registo;

my $fp;
	
open $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@registo = split(/\t/);			
				
	next if(scalar @registo != 12);
	
	next if(index($registo[DATA_HORA],$todays_date)<0);
	next if($registo[RETURN_CODE] eq 'C0000');
	next if(length($registo[STEP_NAME]) eq '-');
	next if(length($registo[START_TIME])!=9);
	next if(length($registo[END_TIME])!=9);
	
	printf("%s %-8s %s %-16s %s %s %s\n",
		substr($registo[DATA_HORA],0,14),
		$registo[JOB_NAME],
		$registo[JOB_NUMBER],
		$registo[STEP_NAME],
		substr($registo[START_TIME],1),
		substr($registo[END_TIME],1),
		$registo[RETURN_CODE]
	);
					
}
	
close $fp;
		
