#TUXJES_ETL_PTARRLD.pl

#REGISTO DO FICHEIRO DE LOG
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;
use constant	START_TIME	=>	6;
use constant	END_TIME	=>	7;
use constant	RETURN_CODE	=>	11;

use strict;
use warnings;
use integer;

use lib 'lib';
require DateCalcFunctions;

my @registo;
my $start_time=0;
my $end_time=0;
my $work;

my $code;

my %step_counter;

my $parm;
my $fp;
my $linhas=0;
my $tot_linhas=0;

my $filename = '/tmp/pkis/logs_ptarrld.csv';

open my $fpo,'>',$filename or die "ERROR $!\n";
printf($fpo "%s\n",$0);
printf($fpo "DATE_TIME;DOMAIN;JOB_NUMBER;JOB_NAME;STEP_NAME;STEP_NUMBER;TIME_SECONDS;RETURN_CODE\n");

while(<DATA>) {

	chomp;
	$parm = $_;
	
	open $fp,'<',$parm or die "ERROR $!\n";
	printf("%s ",$parm);
	$linhas=0;
	
	while(<$fp>) {
	
		next if(length $_ < 20);
		
		chomp;
		@registo = split(/\t/);
			
		next if(scalar @registo != 12);
		next if($registo[STEP_NAME] eq '-');			
		next if(length($registo[START_TIME])!=9);
		next if(length($registo[END_TIME])!=9);
		
		next if($registo[JOB_NAME] !~ /^PTARRLD/);			
		#next if($registo[STEP_NAME] !~ /^FLD1$/);			
		
		$start_time = DateCalcFunctions::time_2_seconds(substr($registo[START_TIME],1));
		$end_time = DateCalcFunctions::time_2_seconds(substr($registo[END_TIME],1));
		$work = DateCalcFunctions::valida_tempos($start_time, $end_time);
		
		$registo[DOMAIN] =~ s/BATCHPRD_//;	
		
		$step_counter{$registo[JOB_NUMBER]}+=1;
		
		printf($fpo "%s;%s;%s;%s;%s;%d;%d;%s\n",
			DateCalcFunctions::data_hora($registo[DATA_HORA]),
			$registo[DOMAIN],
			$registo[JOB_NUMBER],
			$registo[JOB_NAME],
			$registo[STEP_NAME],
			$step_counter{$registo[JOB_NUMBER]},
			$work,
			$registo[RETURN_CODE]
			);	
		$linhas++;
		
	}
	close $fp;
	printf("%5d\n",$linhas);
	$tot_linhas += $linhas;
}	

close $fpo;
printf("File [%s] created, total lines: %d.\n",$filename, $tot_linhas);

__DATA__
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.010619
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.011319
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.012019
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.012719
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.020319
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.021019
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.021719
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.022419
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.030319
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.031019
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.031719
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.032419
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.033019
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.033119
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.040719
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.041419
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.042119
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.042819
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.050519
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.051219
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.051919
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.052619
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.060219
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.060919
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.061619
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.062319
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.063019
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.070719
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.071419
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.072119
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.072819
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.080419
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.081119
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.081819
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.081918
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.082519
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.082618
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.090119
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.090218
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.090819
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.090918
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.091519
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.091618
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.092318
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.093018
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.100718
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.101418
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.102118
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.102818
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.110418
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.111118
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.111818
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.112518
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.120218
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.120918
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.121618
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.122318
/M_I_G_R_A/AT/jes_sys_log/RP/jessys.log.123018