package FileFunctions;

use strict;
use warnings;

use File::Basename;

sub getFileName {

	my $file = shift;
	
	return basename($file);
	
}

sub getFileNameSize {

	my $file = shift;
	
	return (basename($file), -s $file);
	
}

1;