#TUXJES_PRE_MONITOR.pl

#set TUXJESDOMAIN=RP|CO|FO

use strict;
use warnings;

use File::Basename;

my $LAST_LOG_FILE = `ls -t1 \$JESROOT/jessyslog/jessys.log.* | head -1`;
my $BEFORE_LAST_LOG_FILE = `ls -t1 \$JESROOT/jessyslog/jessys.log.* | head -2 | tail  -1`;

chomp $LAST_LOG_FILE;
chomp $BEFORE_LAST_LOG_FILE;

#my $ficheiro_de_entrada = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";
my $ficheiro_de_entrada = $LAST_LOG_FILE;

my $data_log = basename($ficheiro_de_entrada);

#print "DATA LOG: ",$data_log,"\n";
$data_log =~ /(\d+)/;
$data_log = $1;
#print "DATA LOG: ",$data_log,"\n";

my $domain = $ENV{"TUXJESDOMAIN"} || '';

#DOMAIN_MMDDAA.dat
my $control_file = 'datafiles/' . sprintf("%s_%s.dat",$domain,$data_log);

#print "CONTROL-FILE: ",$control_file,"\n";

if(!-e $control_file) {
	system ("perl TUXJES_MONITOR.pl $BEFORE_LAST_LOG_FILE");	
}

system ("perl TUXJES_MONITOR.pl $LAST_LOG_FILE");	

