#!/usr/bin/perl

#TUXJES_MONITOR_EMAILS.pl

use strict;
use warnings;

use constant	DEBUG	=>	1;

my @LOG_DIR;
push @LOG_DIR, "/PRD/EXE_COBOL/PROD/%s/tux/JESROOT/%s/LOG/%s.log";
push @LOG_DIR, "/PRD/EXE_COBOL/PROD/%s/tux/JESROOT/%s.bak/LOG/%s.log";
push @LOG_DIR, "/PRD/EXE_COBOL/PROD/%s/tux/JESROOT_BCK/%s.bak/LOG/%s.log";

my @ARTSTATUS_DIR;
push @ARTSTATUS_DIR, "/PRD/EXE_COBOL/PROD/%s/tux/JESROOT/%s/artstatus";
push @ARTSTATUS_DIR, "/PRD/EXE_COBOL/PROD/%s/tux/JESROOT/%s.bak/artstatus";
push @ARTSTATUS_DIR, "/PRD/EXE_COBOL/PROD/%s/tux/JESROOT_BCK/%s.bak/artstatus";


#PARAMETER PASSED
#domain;jobnumber;jobname;returncode

#EX:
#perl TUXJES_MONITOR_EMAILS.pl CO;00859147;PIFMEF10;S960
#EX:

my $parameters = shift || die "Usage: $0 domain;job_number;job_name;return_code\n";

my $domain = (split(/;/,$parameters))[0];
my $job_number = (split(/;/,$parameters))[1];
my $job_name = (split(/;/,$parameters))[2];
my $return_code = (split(/;/,$parameters))[3];

if(DEBUG) {
	printf("PARAMETER: [%s]\n", $parameters);
	printf("DOMAIN: [%s]\n", $domain);
	printf("JOB-NUMBER: [%s]\n", $job_number);
	printf("JOB-NAME: [%s]\n", $job_name);
	printf("RETURN-CODE: [%s]\n", $return_code);
}

my ($subject, $log_file_contents, $artstatus_status) = ('','','');
my ($log_dir_file, $artatus_file) = ('','');
my ($emailTO, $fileContents) = ('','');

$subject = '[DOMAIN='.$domain.' JOB_NUMBER='.$job_number.' JOB_NAME='.$job_name.' RETURN_CODE='.$return_code;
$subject .=' JOB_STATUS='.get_artstatus_status($artatus_file).' ]';

foreach(@LOG_DIR) {

	$log_dir_file = sprintf("$_",$domain, $job_number, $job_number);
	if(-e $log_dir_file) {
		last;
	}	
}

foreach(@ARTSTATUS_DIR) {

	$artatus_file = sprintf("$_",$domain, $job_number);
	if(-e $artatus_file) {
		last;
	}
}

$subject = '[DOMAIN='.$domain.' JOB_NUMBER='.$job_number.' JOB_NAME='.$job_name.' RETURN_CODE='.$return_code;
$subject .=' JOB_STATUS='.get_artstatus_status($artatus_file).']';

$fileContents = get_log_file_contents($log_dir_file);
$emailTO = get_job_name_contact('emails/'.$job_name);

if(DEBUG) {
	printf("LOG-DIR-FILE: [%s]\n", $log_dir_file);
	printf("ARTSTATUS-FILE: [%s]\n", $artatus_file);
	printf("SUBJECT: [%s]\n", $subject);
	printf("EMAIL-TO: [%s]\n", $emailTO);
	printf("FILE-CONTENTS: [%s]\n", $fileContents);
}
	
#START-SUBROTINAS-------------------------------------------------

sub get_job_name_contact {

	#JOB_NAME
	my $tmp = shift;
	open my $fp,'<',$tmp or die "ERROR - $tmp - $!\n";
	my $line = <$fp>;
	chomp $line;
	close $fp;
	
	return $line;
	
}

sub get_artstatus_status {

	my $tmp = shift;
	
	open my $fp,'<',$tmp or die "ERROR - $tmp - $!\n";
	my $line = <$fp>;
	chomp $line;
	close $fp;

	$line =~ /STATUS=(\w+)/;
	return $1;

}

sub get_log_file_contents {

	my $tmp = shift;
	
	open my $fp,'<',$tmp or die "ERROR - $tmp - $!\n";
	my $lines;
	while(<$fp>) {
		$lines .= $_;
	}
	close $fp;

	return $lines;

}

#END-SUBROTINAS---------------------------------------------------