#TUXJES_DATETIME_JOB_NBR.pl

#REGISTO DO FICHEIRO DE LOG
use constant	DOMAIN		=>	1;
use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;

use strict;
use warnings;
use integer;

use File::Basename;

my @registo;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

my $ficheiro = basename($parm);
$ficheiro =~ /(\d+)/;
$ficheiro = '/tmp/pkis/DATETIME_DATE_XX_'. $1 .'.csv';

my $fich_nbr = '/tmp/pkis/DATETIME_JOBS_XX_'. $1 .'.csv';

my $fp;

my $domain;

my %dates;
my %jobs;

open $fp,'<',$parm or die "ERROR $!\n";
printf("Reading %s ....\n",$parm);

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
		
	@registo = split(/\t/);					
		
	$registo[DOMAIN] =~ s/BATCHPRD_//;		
	$domain = $registo[DOMAIN];
	
	$dates{$registo[DATA_HORA]}+=1;	
	
	$jobs{$registo[JOB_NUMBER]}+=1;
			
}

close $fp;

$ficheiro =~ s/XX/$domain/g;
$fich_nbr =~ s/XX/$domain/g;

open $fp,'>', $ficheiro or die "ERROR $!\n";
printf($fp "%s\n",$0);
printf($fp "DATE_TIME;VALUE\n");

foreach(sort keys %dates) {
	
	printf($fp "%s;%d\n",
		$_,
		$dates{$_}
	);
	

}

close $fp;

printf("%s\n",$ficheiro);

open $fp,'>', $fich_nbr or die "ERROR $!\n";
printf($fp "%s\n",$0);
printf($fp "JOB_NUMBER;VALUE\n");

foreach(sort keys %jobs) {
	
	printf($fp "%s;%d\n",
		$_,
		$jobs{$_}
	);
	
}

close $fp;

printf("%s\n",$fich_nbr);





