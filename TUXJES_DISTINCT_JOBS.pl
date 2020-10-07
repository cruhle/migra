#TUXJES_DISTINCT_JOBS.pl

use strict;
use warnings;

#DESCRICAO DO REGISTO
use constant	DOMAIN		=>	1;
use constant	JOB_NAME	=>	4;
use constant	STEP_NAME	=>	5;

#my $parm = `ls -t1 \$JESROOT/jessyslog/jessys.log.* | head -2 | tail -1`;

my $filename = '/tmp/pkis/jobs_names.csv';

my @lista = qw/co fo rp/;

my @registo;
my %jobs;
my ($key, $fp, $ficheiro, $log_data_file, $old_file_name) = ('', undef, '', '', '');

while(<DATA>) {

	chomp;
	
	$log_data_file = $_;
	
	$old_file_name = $log_data_file;
	
	foreach my $dominio(@lista) {
	
		$log_data_file =~ s/XX/$dominio/;
		
		printf("%s\n",$log_data_file);
		
		load_data_from_log();
		
		$log_data_file = $old_file_name;
	}
	
}	
	
open my $fpout,'>',$filename or die "ERROR $$!\n";
printf($fpout "%s\n",$0);
printf($fpout "DOMAIN;JOB_NAME\n");

foreach(sort keys %jobs) {
	printf($fpout "%s\n",$_);
}
close $fpout;

printf("[%s]\n",$filename);

#-----------------------------------------------------------------------------
sub load_data_from_log {

	open $fp,'<',$log_data_file or die "ERROR $!\n";
			
	while(<$fp>) {
	
		next if(length $_ < 20);
		
		@registo = split(/\t/);			
					
		next if(scalar @registo != 12);		
		next if(length($registo[STEP_NAME]) eq '-');
		
		$registo[DOMAIN] =~ s/BATCHPRD_//;
		$key = $registo[DOMAIN] .';'. $registo[JOB_NAME];
		
		$jobs{$key} = 1;
		
	}
	
	close $fp;
}
#-----------------------------------------------------------------------------
__DATA__
/M_I_G_R_A/AT/jes_sys_log/XX/2019/jessys.log.063019