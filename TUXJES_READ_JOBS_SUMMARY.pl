#TUXJES_READ_JOBS_SUMMARY.pl

use strict;
use warnings;

my $input_file = shift || die "Usage: $0 JOBS-SUMMARY-FILE-TO-PROCESS\n";

if(!-e $input_file) {
	print "Ficheiro [$input_file] nao encontrado!\n";
	exit;
}

my $output_file = uc($input_file);
$output_file =~ s/JOBS_SUMMARY/R_PLOT/g;

my $file_dates = $input_file;
#$file_dates =~ /(\d{8}_\d{8})/;
$file_dates =~ /(\d{4})(\d{2})(\d{2})_(\d{4})(\d{2})(\d{2})/;
$file_dates = $1.'-'.$2.'-'.$3. ' - ' . $4.'-'.$5.'-'.$6;

my $job_name;
my $job_runs;

my %jobs;
my $key;
my @runs;

my $x_value;
my $y_value;

open my $fp,'<',$input_file or die "ERROR $!\n";
open my $fout,'>',$output_file or die "ERROR $!\n";
<$fp>;
<$fp>;
while(<$fp>) {
	chomp;
	($job_name,$job_runs) = split(/;/);
	#print "$job_name\n$job_runs\n\n";
	
	@runs = split(/,/,$job_runs);
	
	foreach(@runs) {
		$jobs{$job_name}{$_}+=1;
		if($jobs{$job_name}{$_}==1) {	
			$jobs{$job_name}{'KEYS'} .= ',' . $_;
		}
	}
	
	#print "$job_name\n";
	$job_runs = substr($jobs{$job_name}{'KEYS'},1);
	@runs = split(/,/,$job_runs);
	
	$x_value='';
	$y_value='';
	#sort ASCENDING
	foreach(sort { $a <=> $b } @runs) {
		$x_value .= ',' . $_;
		$y_value .= ',' . $jobs{$job_name}{$_}
	}
	
	$x_value = 'x<-c('.substr($x_value,1) .')';
	$y_value = 'y<-c('.substr($y_value,1) .')';

	#print "$x_value";
	#print "\n$y_value\n";
	
	printf($fout "---------------%s-----------------\n",
		$job_name
	);
	
	#printf($fout "%s;%s\n%s;%s\n\n",
	#	$job_name,
	#	$x_value,
	#	$job_name,
	#	$y_value
	#);	
	
	printf($fout "%s\n%s\n\nplot(x,y, main=\"%s [%s]\",xlab=\"Seconds\", ylab=\"Job Runs\",pch=19)\n\n",
		$x_value,
		$y_value,
		$job_name,
		$file_dates
	);			
	
}

close $fp;
close $fout;

print "File created: $output_file\n";









