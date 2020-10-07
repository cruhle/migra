#TUXJES_POWER_BI_MONTHLY.pl

#cria ficheiro mensal
#INPUT	__DATA__ os ficheiros a serem processados
#OUTPUT	output o nome do ficheiro a ser processado pelo BI

#ficheiros para POWER BI

#DESCRICAO DO REGISTO
#use constant	SERVIDOR	=>	0;
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

use lib 'lib';
require DateCalcFunctions;

my $file_in;
my $fp;

my %output;
my $key;
my $work;

my @registo;
my $domain='-1';
my $s_data;
my $e_data;

my ($in_lines, $out_lines) = (0,0);

#OUTPUT
my $file_out = '/tmp/pkis/month/monthly_201909.csv';
#OUTPUT

while(<DATA>) {

	chomp;
	$file_in = $_;

	printf("%s\n",$file_in);
	
	open my $fp,'<',$file_in or die "ERROR $!\n";
	
	while(<$fp>) {

		$in_lines++;
	
		next if(length $_ < 20);
		
		chomp;
		@registo = split(/\t/);
		next if(scalar @registo != 12);
		
		next if($registo[STEP_NAME] eq '-');
		next if(length($registo[START_TIME])!=9);
		next if(length($registo[END_TIME])!=9);	
	
		$s_data = (split(/\s/,$registo[DATA_HORA]))[0];
		
		#ALTERAR DATA NO FICHEIRO!!!!
		next if($s_data !~ /201909/);
		
		$e_data = $s_data;
		
		$registo[START_TIME] =~ s/S//;	
		$registo[END_TIME] =~ s/E//;		
		
		if($registo[START_TIME] gt $registo[END_TIME]) {
			$s_data = DateCalcFunctions::getYesterdayYYYYMMDD($s_data);
		}
		
		$work = DateCalcFunctions::get_seconds_work_time(
				($s_data . ' ' . $registo[START_TIME]),
				($e_data . ' ' . $registo[END_TIME])
				);
		
		if($domain eq '-1') {
			$registo[DOMAIN] =~ s/BATCHPRD_//;	
			$domain = $registo[DOMAIN];
		}
		
		$key = getDateFormated($e_data) .';'. $domain .';'. $registo[JOB_NUMBER];
		
		if(exists($output{$key})) {
			$output{$key}{'worktime'} += $work;
			if($output{$key}{'return_code'} eq 'C0000') {
				$output{$key}{'return_code'} = $registo[RETURN_CODE];
			}
		} else {
			$output{$key}{'worktime'} = $work;
			$output{$key}{'jobname'} = $registo[JOB_NAME];
			$output{$key}{'return_code'} = $registo[RETURN_CODE];
		}
			
	}

	close $fp;
	
}

#------------------------------------------------------

open $fp,'>', $file_out or die "ERROR $!\n";
#printf($fp "%s\n",$0);
printf($fp "DATE;DOMAIN;JOB_NUMBER;JOB_NAME;JOB_RUNTIME_SECONDS;RETURN_CODE\n");

foreach(sort keys %output) {
	$out_lines++;
	printf($fp "%s;%s;%d;%s\n",
			$_,
			$output{$_}{'jobname'},
			$output{$_}{'worktime'},
			$output{$_}{'return_code'}
		);
}
close $fp;

printf("%s\n",$file_out);
printf("Lines read: %d, lines written: %d\n",$in_lines, $out_lines);

#------------------------------------------------------

sub getDateFormated {

	my $z = shift;
	
	$z =~ /^(\d{4})(\d{2})(\d{2})$/;
	
	return sprintf("%d-%02d-%02d", $1, $2, $3);
}

__DATA__
/M_I_G_R_A/AT/jes_sys_log/rp/2019/jessys.log.090119
/M_I_G_R_A/AT/jes_sys_log/rp/2019/jessys.log.090819
/M_I_G_R_A/AT/jes_sys_log/rp/2019/jessys.log.091519
/M_I_G_R_A/AT/jes_sys_log/rp/2019/jessys.log.092219
/M_I_G_R_A/AT/jes_sys_log/rp/2019/jessys.log.092919
/M_I_G_R_A/AT/jes_sys_log/fo/2019/jessys.log.090119
/M_I_G_R_A/AT/jes_sys_log/fo/2019/jessys.log.090819
/M_I_G_R_A/AT/jes_sys_log/fo/2019/jessys.log.091519
/M_I_G_R_A/AT/jes_sys_log/fo/2019/jessys.log.092219
/M_I_G_R_A/AT/jes_sys_log/fo/2019/jessys.log.092919
/M_I_G_R_A/AT/jes_sys_log/co/2019/jessys.log.082519
/M_I_G_R_A/AT/jes_sys_log/co/2019/jessys.log.090119
/M_I_G_R_A/AT/jes_sys_log/co/2019/jessys.log.090819
/M_I_G_R_A/AT/jes_sys_log/co/2019/jessys.log.091519
/M_I_G_R_A/AT/jes_sys_log/co/2019/jessys.log.092219
/M_I_G_R_A/AT/jes_sys_log/co/2019/jessys.log.092919
/M_I_G_R_A/AT/jes_sys_log/pr/2019/jessys.log.082519
/M_I_G_R_A/AT/jes_sys_log/pr/2019/jessys.log.090119
/M_I_G_R_A/AT/jes_sys_log/pr/2019/jessys.log.090819
/M_I_G_R_A/AT/jes_sys_log/pr/2019/jessys.log.091519
/M_I_G_R_A/AT/jes_sys_log/pr/2019/jessys.log.092219
/M_I_G_R_A/AT/jes_sys_log/pr/2019/jessys.log.092919
/M_I_G_R_A/AT/jes_sys_log/misc/2019/jessys.log.082519
/M_I_G_R_A/AT/jes_sys_log/misc/2019/jessys.log.090119
/M_I_G_R_A/AT/jes_sys_log/misc/2019/jessys.log.090819
/M_I_G_R_A/AT/jes_sys_log/misc/2019/jessys.log.091519
/M_I_G_R_A/AT/jes_sys_log/misc/2019/jessys.log.092219
/M_I_G_R_A/AT/jes_sys_log/misc/2019/jessys.log.092919
