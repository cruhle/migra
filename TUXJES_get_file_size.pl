#TUXJES_get_file_size.pl

use strict;
use warnings;
use File::Basename;

use lib 'lib';
require DateCalcFunctions;

my ($parm) =  @ARGV; 

if (not defined $parm) {
  die "Falta o nome do FICHEIRO para ser processado!\n";
}

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my $ficheiro_de_input = $parm;

my $current_file = basename($parm);
my $file_directory = dirname($parm);

my $domain = $ENV{"TUXJESDOMAIN"} || '';
if($domain eq '') {
	print "ERRO falta  --> TUXJESDOMAIN <-- variavel.\n";
	exit;
}

my $current_file_size = -s $parm;

my $control_file = 'log/seek_' . $domain;
my $fp;
my $last_file_size=0;
my $last_file_name='';

if(-e $control_file) {
	open $fp,'<',$control_file;
	($last_file_name, $last_file_size) = split(/;/,<$fp>);
	close $fp;
}

if($current_file eq $last_file_name) {
	if($last_file_size > $current_file_size) {
		$last_file_size = 0;
	}
} else {
	open $fp,'<',$file_directory.'/'.$last_file_name;
	seek($fp,$last_file_size,0);
	while(<$fp>) {
		print;
	}
	close $fp;
	$last_file_size = 0;
}

open $fp,'<',$ficheiro_de_input or die "ERROR $!\n";
seek($fp,$last_file_size,0);
while(<$fp>) {
	print;
}
close $fp;

open $fp,'>',$control_file;
printf($fp "%s;%d", $current_file, $current_file_size);
close $fp;

$control_file = $control_file .'_log';
open $fp,'>>',$control_file;
printf($fp "%s;%s;%d;%s;%d\n", 
	DateCalcFunctions::getLocaltime(),
	$last_file_name, 
	$last_file_size, 
	$current_file, 
	$current_file_size
	);
close $fp;



