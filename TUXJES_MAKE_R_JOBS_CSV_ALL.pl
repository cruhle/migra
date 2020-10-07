#TUXJES_MAKE_R_JOBS_CSV_ALL.pl

#/DEV/user/cobol_dv/load_csv

#ALTERAR O NOME DO FICHEIRO DE OUTPUT
#RP	CO FO
#ALTERAR OS FICHEIROS EM __DATA__

use strict;
use warnings;
use File::Basename;
use Date::Calc qw(Day_of_Week);

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

use constant	DEBUG		=>	0;

#my $parm = `ls -t1 \$JESROOT/jessyslog/jessys.log.* | head -2 | tail -1`;

my $filename = '/tmp/pkis/R_jobs.csv';

my @registo;
my %paraimprimir;
my %day_of_week;
my %r_datas;
my $fpout;

my ($key, $domain, $fp, $ficheiro) = ('','', undef, '');
my ($start_time, $end_time, $work, $lnhs)=(0, 0, 0, 0);

open $fpout,'>',$filename or die "ERROR $$!\n";
printf($fpout "%s\n",$0);
printf($fpout "YEAR;MONTH;DAY;WEEK_DAY;DOMAIN;JOB_NUMBER;JOB_NAME;RUNTIME_SECONDS;RETURN_CODE\n");
close $fpout;

while(<DATA>) {
	chomp;
	$ficheiro = $_;
	printf("%s\n",$ficheiro);
	
	open $fp,'<',$ficheiro or die "ERROR $!\n";

	%paraimprimir = ();
	
	while(<$fp>) {
	
		next if(length $_ < 20);
		
		chomp;
		@registo = split(/\t/);			
					
		next if(scalar @registo != 12);
		
		next if(index($registo[DATA_HORA],'2019') == -1 );
		next if(index($registo[DATA_HORA],'201907') == 0 );
		next if(length($registo[STEP_NAME]) eq '-');
		next if(length($registo[START_TIME])!=9);
		next if(length($registo[END_TIME])!=9);
				
		$start_time = DateCalcFunctions::time_2_seconds(substr($registo[START_TIME],1));
		$end_time = DateCalcFunctions::time_2_seconds(substr($registo[END_TIME],1));		
		$work = DateCalcFunctions::valida_tempos($start_time, $end_time);	
		
		if($domain eq '') {
			$registo[DOMAIN] =~ s/BATCHPRD_//;
			$domain = $registo[DOMAIN];
		}
		
		$key = $registo[JOB_NUMBER];					
		
		if(!exists($paraimprimir{$key})) {			 
			$paraimprimir{$key}{'data'} = separa_data($registo[DATA_HORA]);
			$paraimprimir{$key}{'weekday'} = dia_da_semana($registo[DATA_HORA]);
			$paraimprimir{$key}{'job_name'} = $registo[JOB_NAME];			 
			$paraimprimir{$key}{'domain'} = $domain;
			$paraimprimir{$key}{'retcode'} = $registo[RETURN_CODE];
		}
			
		$paraimprimir{$key}{'work'} += $work;
		$paraimprimir{$key}{'retcode'} = $registo[RETURN_CODE] if($registo[RETURN_CODE] ne 'C0000');
		
	}
	
	close $fp;
		
	open $fpout,'>>',$filename or die "ERROR $$!\n";
	
	foreach(sort keys %paraimprimir) {
		$lnhs++;
		printf($fpout "%s;%d;%s;%s;%s;%d;%s\n",
			$paraimprimir{$_}{'data'},
			$paraimprimir{$_}{'weekday'},
			$paraimprimir{$_}{'domain'},
			$_,
			$paraimprimir{$_}{'job_name'},
			$paraimprimir{$_}{'work'},
			$paraimprimir{$_}{'retcode'}
		);
	}
	
	close $fpout;
}

printf("[%s] [%d]\n",$filename, $lnhs) if(!DEBUG);

#-----------------------------------------------------------------------------
if(DEBUG) {

	foreach(sort keys %r_datas) {
		printf("%s\t%s\n",$_, $r_datas{$_});
	}
	print "\n\n";
	foreach(sort keys %day_of_week) {
		printf("%s\t%d\n",$_, $day_of_week{$_});
	}
	
	printf("[%s] [%d]\n",$filename, $lnhs);
}
#-----------------------------------------------------------------------------
sub separa_data {

	my $tmp = shift;	
	$tmp = (split(/\s/,$tmp))[0];
	
	my ($ano, $mes, $dia) = (0,0,0);
	
	if(!exists($r_datas{$tmp})) {
		$ano = substr((split(/\s/,$tmp))[0],0,4);
		$mes = substr((split(/\s/,$tmp))[0],4,2);
		$dia = substr((split(/\s/,$tmp))[0],6,2);
		
		$r_datas{$tmp} = sprintf("%d;%02d;%02d",$ano,$mes,$dia);
	}
	
	return $r_datas{$tmp};
}

sub dia_da_semana {

	my $tmp = shift;
	$tmp = (split(/\s/,$tmp))[0];
	
	if(!exists($day_of_week{$tmp})) {
		my $ano = substr((split(/\s/,$tmp))[0],0,4);
		my $mes = substr((split(/\s/,$tmp))[0],4,2);
		my $dia = substr((split(/\s/,$tmp))[0],6,2);
		$day_of_week{$tmp} = Day_of_Week($ano, $mes, $dia);
	}
	
	return $day_of_week{$tmp};
}
#-----------------------------------------------------------------------------
__DATA__
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.123018
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.010619
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.011319
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.012019
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.012719
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.020319
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.021019
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.021719
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.022419
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.030319
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.031019
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.031719
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.032419
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.033019
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.033119
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.040719
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.041419
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.042119
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.042819
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.050519
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.051219
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.051919
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.052619
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.060219
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.060919
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.061619
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.062319
/M_I_G_R_A/AT/jes_sys_log/rp/jessys.log.063019
