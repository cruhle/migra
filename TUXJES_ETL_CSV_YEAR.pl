#TUXJES_ETL_CSV_YEAR.pl

use strict;
use warnings;
use File::Basename;

use lib 'lib';
require DateCalcFunctions;

#DESCRICAO DO REGISTO
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
use constant	START_TIME	=>	6;
use constant	END_TIME	=>	7;
use constant	RETURN_CODE	=>	11;

my $filename = '/tmp/pkis/tuxjes_steps_2018.csv';

my @registo;
my %contador;
my ($key, $domain, $fp, $ficheiro) = ('','', undef, '');
my ($start_time, $end_time, $work, $lnhs)=(0, 0, 0, 0);

open my $fpout,'>',$filename or die "ERROR $$!\n";
printf($fpout "%s\n",$0);
printf($fpout "DATE_TIME;DOMAIN;JOB_NUMBER;JOB_NAME;STEP_NAME;STEP_NUMBER;TIME_SECONDS;RETURN_CODE\n");

while(<DATA>) {

	chomp;
	$ficheiro = $_;	
	
	open $fp,'<',$ficheiro or die "ERROR $!\n";
	printf("%s\n",$ficheiro);	
	
	while(<$fp>) {
	
		next if(length $_ < 20);
		
		chomp;
		@registo = split(/\t/);			
			
		next if(index($registo[DATA_HORA],'2018') == -1 );
		next if(scalar @registo != 12);
		next if(length($registo[STEP_NAME]) eq '-');
		next if(length($registo[START_TIME])!=9);
		next if(length($registo[END_TIME])!=9);
				
		$start_time = DateCalcFunctions::time_2_seconds(substr($registo[START_TIME],1));
		$end_time = DateCalcFunctions::time_2_seconds(substr($registo[END_TIME],1));		
		$work = DateCalcFunctions::valida_tempos($start_time, $end_time);	
		$registo[DOMAIN] =~ s/BATCHPRD_//;
		$domain = $registo[DOMAIN];
		
		$key = $registo[JOB_NUMBER] .';'. $registo[JOB_NAME];
			
		$contador{$key}+=1;
		
		printf($fpout "%s;%s;%s;%s;%s;%d;%d;%s\n",
			$registo[DATA_HORA],
			$registo[DOMAIN],
			$registo[JOB_NUMBER],
			$registo[JOB_NAME], 
			$registo[STEP_NAME],
			$contador{$key},
			$work,
			$registo[RETURN_CODE]
		); 
		
		$lnhs++;
	}
	close $fp;
	
}	
close $fpout;

printf("[%s] [%d]\n",$filename, $lnhs);

__DATA__
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.081918
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.082618
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.090218
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.090918
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.091618
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.092318
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.093018
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.100718
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.101418
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.102118
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.102818
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.110418
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.111118
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.111818
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.112518
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.120218
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.120918
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.121618
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.122318
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.123018
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.082618
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.090218
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.090918
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.091618
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.092318
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.093018
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.100718
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.101418
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.102118
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.102818
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.110418
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.111118
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.111818
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.112518
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.120218
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.120918
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.121618
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.122318
/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.123018
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.081218
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.081918
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.082618
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.090218
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.090918
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.091618
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.092318
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.093018
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.100718
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.101418
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.102118
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.102818
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.110418
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.111118
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.111818
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.112518
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.120218
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.120918
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.121618
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.122318
/M_I_G_R_A/AT/jes_sys_log/fo/jessys.log.123018