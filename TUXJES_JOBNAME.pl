#TUXJES_JOBNAME.pl

#DESCRICAO DO REGISTO

use constant	DATA_HORA	=>	2;
use constant	JOB_NUMBER	=>	3;
use constant	JOB_NAME	=>	4;
use constant	RETURN_CODE	=>	11;

use strict;
use warnings;

my ($seek_job) =  @ARGV; # or die "Usage: $0 NOME-DO-JOB-A-PESQUISAR\n";

if($#ARGV!=0) {
	printf("\nPARAMETROS\tERRO\tERRO\tERRO\t");
	printf("Faltam parametros: JOBNAME\n");
	exit;
}

if (not defined $seek_job) {  die "Falta o JOBNAME.\n"; }

if($seek_job !~ /^[a-zA-Z0-9]{2,8}$/) {
	printf("JOBNAME: LETRAS e/OU NUMEROS! MIN: 2 - MAX: 8!\n");
	exit;
}

#my $parm = `ls -t1 \$JESROOT/jessyslog/jessys.log.* | head -1`;

my $parm = '/M_I_G_R_A/AT/jes_sys_log/co/jessys.log.051219';
#my @ficheiros = "dir \\M_I_G_R_A\\AT\\jes_sys_log\\CO\\jessys.log.* /s/b /o-d";
my @ins;

my %dados_jobname;
my %jobname_dia;
my $data;
my $job;
$seek_job = uc($seek_job);

open my $fp,'<',$parm or die "ERROR $parm read error $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	@ins = split(/\t/);
	next if(scalar @ins != 12);
	next if($ins[RETURN_CODE] eq 'C0000');
	
	$data = $ins[DATA_HORA];
	$data =~ s/\s/\t/;
	$job = $ins[JOB_NAME];
	
	#if($seek_job =~ m/$job/) {
	if($job =~ m/$seek_job/) {
		printf("%s\t\%s\t%s\t%s\n",
			$data,
			$ins[JOB_NAME],
			$ins[JOB_NUMBER],
			$ins[RETURN_CODE]
		);
	}
	
}
close $fp;


#------------------------------------------------------

