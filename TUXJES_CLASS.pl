#TUXJES_CLASS.pl

use strict;
use warnings;

my $ficheiro = shift || die "ERROR - FILE TO READ?\n";

if(!-e $ficheiro) {
	die "File [$ficheiro] not found.\n";
}

use constant	DOMAIN	=>	1;
use constant	DATA	=>	2;
use constant	CLASS	=>	9;

my @registo;
my %classes;
my $key;

open my $fp,'<',$ficheiro or die "ERROR $!\n";
while(<$fp>) {
	
	if(/STARTED/) {
		chomp;
		@registo = split(/\t/);
		$key = @registo;
		next if($key!=15);
		$registo[DOMAIN] =~ s/BATCHPRD_//;	
		$registo[DATA] = (split(/\s/,$registo[DATA]))[0];
		$key = $registo[DATA] .';'. $registo[DOMAIN] .';'.$registo[CLASS];
		$classes{$key}+=1;
	}
}
close $fp;

foreach(sort keys %classes) {
	printf("%s;%d\n",$_, $classes{$_});
}

