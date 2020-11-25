#TUXJES_XLS_STARTED_ENDED.pl

#REGISTO DO FICHEIRO DE LOG
use constant	SERVER			=>	0;
use constant	DOMAIN			=>	1;
use constant	DATA_HORA		=>	2;
use constant	JOB_NUMBER		=>	3;
use constant	JOB_NAME		=>	4;
use constant	JOB_STATUS		=>	6;
use constant	RETURN_CODE		=>	7;
use constant	CLASS			=>	9;

use strict;
use warnings;
use integer;

use Excel::Writer::XLSX;
use Date::Calc qw(Add_Delta_Days);

use File::Basename;

use lib 'lib';
require DateCalcFunctions;

my @registo;

my $parm = shift || die "Usage: $0 LOG-FILE-TO-PROCESS\n";

if(!-e $parm) {
	print "Ficheiro [$parm] nao encontrado!\n";
	exit;
}

my $ficheiro = basename($parm);
$ficheiro =~ /(\d+)/;
#$ficheiro = '/tmp/pkis/started_ended_XX_'. $1 .'.xlsx';

my $xficheiro = getDateRange($1);
$ficheiro = '/tmp/pkis/XX_'. $xficheiro .'.xlsx';
my $fich_bi = '/tmp/pkis/XX_BI_'. $xficheiro .'.csv';
#my $fich_acm = '/tmp/pkis/'. $xficheiro .'.csv';
my $started_date = (split(/_/,$xficheiro))[0];
my $fich_summary = '/tmp/pkis/XX_JOBS_SUMMARY_'. $xficheiro .'.csv';

my $fp;
my $domain;

my %jobs;

open $fp,'<',$parm or die "ERROR $!\n";

while(<$fp>) {

	next if(length $_ < 20);
	
	chomp;
	
	next if($_ !~ /(STARTED|ENDED)/);
#IM	next if($_ !~ /(PIFMEF21|PTFMEF22|PTFMEF23|PTFMEF24|PTFMEF76|
#IM					PTFMEF78|PIFMEF20|PTFMEF66|PTFMEF11|PTFMEF12|
#IM					PTFMFC10|PTFMFC11|PTFMFC12|PTFMFC13|PTFMFC14|
#IM					PTFMFC15|PTFMFCW0|PTFMFCW1|PTFMFCW2|PTFMFC60|
#IM					PTFMFCA0|PTFMFCB0|PTFMFCC0|PTFMFC90)/);
#IM	
	@registo = split(/\t/);					
	
	#next if($registo[JOB_NAME] !~ /^PIFMFC/);
		
	$registo[DOMAIN] =~ s/BATCHPRD_//;	
	
	#QUALIDADE
	#$registo[DOMAIN] =~ s/BATCHDEV_//;	
	#next if($registo[JOB_NAME] !~ /^TITETS15$/);
	#QUALIDADE
	
	$domain = $registo[DOMAIN];
	
	$jobs{$registo[JOB_NUMBER]}{$registo[JOB_STATUS]} = $registo[DATA_HORA];
	$jobs{$registo[JOB_NUMBER]}{'SERVER'} = $registo[SERVER];
	$jobs{$registo[JOB_NUMBER]}{'DOMAIN'} = $registo[DOMAIN];
	$jobs{$registo[JOB_NUMBER]}{'JOB_NAME'} = $registo[JOB_NAME];
	
	if($registo[JOB_STATUS] eq 'STARTED') {
		$jobs{$registo[JOB_NUMBER]}{'CLASS'} = $registo[CLASS];
	}
	
	if($registo[JOB_STATUS] eq 'ENDED') {
		$jobs{$registo[JOB_NUMBER]}{'RETURN_CODE'} = $registo[RETURN_CODE];
	}
}

close $fp;

$ficheiro =~ s/XX/$domain/g;
$fich_bi =~ s/XX/$domain/g;
$fich_summary =~ s/XX/$domain/g;

my $Excelbook = Excel::Writer::XLSX->new( $ficheiro ); 
my $sheet_total = $Excelbook->add_worksheet('GRAND_TOTAL'); 
my $sheet_header = $Excelbook->add_worksheet('FULL_DETAIL'); 
my $sheet_detail = $Excelbook->add_worksheet('JOBS_DAILY'); 
my $sheet_trailer = $Excelbook->add_worksheet('TOTAL_JOBS'); 
my $top10_runs = $Excelbook->add_worksheet('TOP_10_JOB_RUNS'); 
my $top10_time = $Excelbook->add_worksheet('TOP_10_JOB_TIMES'); 
my $ret_codes = $Excelbook->add_worksheet('RETURN_CODES'); 
my $error_jobs = $Excelbook->add_worksheet('JOBS_WITH_ERRORS'); 

$sheet_header->freeze_panes( 1, 0 );
$sheet_detail->freeze_panes( 1, 0 );
$sheet_trailer->freeze_panes( 1, 0 );

my $format_header = $Excelbook->add_format();
$format_header->set_bg_color('black');
$format_header->set_color('white');		
$format_header->set_bold();		
$format_header->set_size(11);
$format_header->set_align('center');
	
my $format_detail = $Excelbook->add_format();
$format_detail->set_size(11);
$format_detail->set_align('center');	

my $xls_row=1;
my $xls_error_row=1;
my $xls_col=0;

write_header_labels();

my $key;
my %total_por_job;
my %so_jobs;
my %return_codes;
my %job_dims;

my $status = 1;
my $complete = 1;

open $fp,'>',$fich_bi or die "ERROR $!\n";
printf($fp "%s\n",$0);
printf($fp "SERVER;JOB_NUMBER;JOB_NAME;DOMAIN;CLASS;JOB_DATE;JOB_HOUR;RUNTIME_SECONDS;RETURN_CODE\n");

foreach(sort keys %jobs) {
	
	#if(!exists($jobs{$_}{'STARTED'})) {
	#	$jobs{$_}{'STARTED'}='19700101 00:00:00';
	#	$jobs{$_}{'CLASS'} = '-';
	#	$status=0;
	#	$complete = 0;
	#}
	
	#if(!exists($jobs{$_}{'ENDED'})) {
	#	$jobs{$_}{'ENDED'}='19700101 00:00:00';
	#	$jobs{$_}{'RETURN_CODE'}='';
	#	$status=0;
	#	$complete = 0;
	#}		
	
	next if(!exists($jobs{$_}{'STARTED'}));
	next if(!exists($jobs{$_}{'ENDED'}));
	
	#if($status==1) {
		$status = DateCalcFunctions::get_seconds_work_time(
			$jobs{$_}{'STARTED'} , $jobs{$_}{'ENDED'} );
	#}

	$key = (split(/\s/,$jobs{$_}{'STARTED'}))[0];
	$key .= ';'.$jobs{$_}{'JOB_NAME'};
	$total_por_job{$key}{'QTD'} += 1;
	$total_por_job{$key}{'SECONDS'} += $status;
	
	$key = $jobs{$_}{'JOB_NAME'};
	$so_jobs{$key}{'QTD'} += 1;
	$so_jobs{$key}{'SECONDS'} += $status;
	
	printf($fp "%s;%s;%s;%s;%s;%s;%d;%s\n",
		$jobs{$_}{'SERVER'},
		$_,
		$jobs{$_}{'JOB_NAME'},
		$jobs{$_}{'DOMAIN'},
		$jobs{$_}{'CLASS'},
		clearDate($jobs{$_}{'STARTED'}),
		$status,
		$jobs{$_}{'RETURN_CODE'}
	);
	
	$return_codes{$jobs{$_}{'RETURN_CODE'}}+=1;
	
	if(!isReturnCodeError($jobs{$_}{'RETURN_CODE'})) {
		$job_dims{$jobs{$_}{'JOB_NAME'}} .= ','.$status;
	}
	

	$sheet_header->write( $xls_row, $xls_col , $jobs{$_}{'SERVER'}, $format_detail ); 
	$xls_col += 1;
	$sheet_header->write( $xls_row, $xls_col , $_, $format_detail ); 
	$xls_col += 1;
	$sheet_header->write( $xls_row, $xls_col , $jobs{$_}{'JOB_NAME'}, $format_detail ); 
	$xls_col += 1;
	$sheet_header->write( $xls_row, $xls_col , $jobs{$_}{'DOMAIN'}, $format_detail ); 
	$xls_col += 1;
	$sheet_header->write( $xls_row, $xls_col , $jobs{$_}{'CLASS'}, $format_detail ); 
	$xls_col += 1;
	$sheet_header->write( $xls_row, $xls_col , $jobs{$_}{'STARTED'}, $format_detail ); 
	$xls_col += 1;
	$sheet_header->write( $xls_row, $xls_col , $jobs{$_}{'ENDED'}, $format_detail ); 
	$xls_col += 1;
	$sheet_header->write( $xls_row, $xls_col , $status, $format_detail ); 
	$xls_col += 1;
	$sheet_header->write( $xls_row, $xls_col , $jobs{$_}{'RETURN_CODE'}, $format_detail ); 
	$xls_col += 1;
	
	$xls_row += 1;
	$xls_col = 0;
	
	#ERROR JOBS
	if(isReturnCodeError($jobs{$_}{'RETURN_CODE'})) {
		$error_jobs->write( $xls_error_row, $xls_col , $jobs{$_}{'SERVER'}, $format_detail ); 
		$xls_col += 1;
		$error_jobs->write( $xls_error_row, $xls_col , $_, $format_detail ); 
		$xls_col += 1;
		$error_jobs->write( $xls_error_row, $xls_col , $jobs{$_}{'JOB_NAME'}, $format_detail ); 
		$xls_col += 1;
		$error_jobs->write( $xls_error_row, $xls_col , $jobs{$_}{'DOMAIN'}, $format_detail ); 
		$xls_col += 1;
		$error_jobs->write( $xls_error_row, $xls_col , $jobs{$_}{'CLASS'}, $format_detail ); 
		$xls_col += 1;
		$error_jobs->write( $xls_error_row, $xls_col , $jobs{$_}{'STARTED'}, $format_detail ); 
		$xls_col += 1;
		$error_jobs->write( $xls_error_row, $xls_col , $jobs{$_}{'ENDED'}, $format_detail ); 
		$xls_col += 1;
		$error_jobs->write( $xls_error_row, $xls_col , $status, $format_detail ); 
		$xls_col += 1;
		$error_jobs->write( $xls_error_row, $xls_col , $jobs{$_}{'RETURN_CODE'}, $format_detail ); 
		$xls_error_row+=1;
	}
	#ERROR JOBS
	$xls_col = 0;
	
	$status = 1;
	$complete = 1;

}

close $fp;
close $fich_bi;
printf("%s\n",$fich_bi);

open $fp,'>',$fich_summary;
printf($fp "%s\n",$0);
printf($fp "JOB_NAME;JOB_RUNTIME_SECONDS\n");
foreach(sort keys %job_dims) {
	printf($fp "%s;%s\n",
	$_,
	substr($job_dims{$_},1)
	);
}
close $fp;
printf("%s\n",$fich_summary);

$xls_row=1;
$xls_col=0;
my %grand_total;
foreach(sort keys %total_por_job) {
		
		$sheet_detail->write( $xls_row, $xls_col , (split(/;/,$_))[0], $format_detail ); 
		$xls_col += 1;
		$sheet_detail->write( $xls_row, $xls_col , (split(/;/,$_))[1], $format_detail ); 
		$xls_col += 1;
		$sheet_detail->write( $xls_row, $xls_col , $total_por_job{$_}{'QTD'}, $format_detail ); 
		$xls_col += 1;
		$sheet_detail->write( $xls_row, $xls_col , $total_por_job{$_}{'SECONDS'}, $format_detail ); 
		$xls_col = 0;
		$xls_row += 1;
		
		$grand_total{(split(/;/,$_))[0]}{'QTD'} += $total_por_job{$_}{'QTD'};
		$grand_total{(split(/;/,$_))[0]}{'SECONDS'} += $total_por_job{$_}{'SECONDS'};
		
}

$xls_row=1;
$xls_col=0;

###################################
#ACM
###################################
#if (!-e $fich_acm) {
#	open $fp,'>',$fich_acm or die "ERROR $!\n";
#	printf($fp "%s\n",$0);
#	printf($fp "STARTED_DATE;DOMAIN;JOB_NAME;TOTAL_JOB_RUNS;TOTAL_RUNTIME_SECONDS\n");
#} else {
#	open $fp,'>>',$fich_acm or die "ERROR $!\n";
#}	

foreach(sort keys %so_jobs) {
		
		$sheet_trailer->write( $xls_row, $xls_col , $_, $format_detail ); 
		$xls_col += 1;
		$sheet_trailer->write( $xls_row, $xls_col , $so_jobs{$_}{'QTD'}, $format_detail ); 
		$xls_col += 1;
		$sheet_trailer->write( $xls_row, $xls_col , $so_jobs{$_}{'SECONDS'}, $format_detail ); 
				
		$xls_col = 0;
		$xls_row += 1;
		
		#printf($fp "%s;%s;%s;%d;%d\n",
		#	$started_date,
		#	$domain,
		#	$_,
		#	$so_jobs{$_}{'QTD'},
		#	$so_jobs{$_}{'SECONDS'}
		#);
		
}

#close $fp;
#printf("%s\n",$fich_acm);

$xls_row=1;
$xls_col=0;
$key=0;

foreach(sort {$so_jobs{$b}{'QTD'} <=> $so_jobs{$a}{'QTD'}} keys %so_jobs) {

		$top10_runs->write( $xls_row, $xls_col , $_, $format_detail ); 
		$xls_col += 1;
		$top10_runs->write( $xls_row, $xls_col , $so_jobs{$_}{'QTD'}, $format_detail ); 
		$xls_col += 1;
		$top10_runs->write( $xls_row, $xls_col , $so_jobs{$_}{'SECONDS'}, $format_detail ); 
		
		$xls_col += 1;
		$top10_runs->write( $xls_row, $xls_col , DateCalcFunctions::seconds_2_hh_mm_str($so_jobs{$_}{'SECONDS'}), $format_detail ); 	
					
		$xls_col = 0;
		$xls_row += 1;
        
		$key++;
		last if($key==10);
}


$xls_row=1;
$xls_col=0;
$key=0;

foreach(sort {$so_jobs{$b}{'SECONDS'} <=> $so_jobs{$a}{'SECONDS'}} keys %so_jobs) {

		$top10_time->write( $xls_row, $xls_col , $_, $format_detail ); 
		$xls_col += 1;
		$top10_time->write( $xls_row, $xls_col , $so_jobs{$_}{'QTD'}, $format_detail ); 
		$xls_col += 1;
		$top10_time->write( $xls_row, $xls_col , $so_jobs{$_}{'SECONDS'}, $format_detail ); 
		
		$xls_col += 1;
		$top10_time->write( $xls_row, $xls_col , DateCalcFunctions::seconds_2_hh_mm_str($so_jobs{$_}{'SECONDS'}), $format_detail ); 	
		
		$xls_col = 0;
		$xls_row += 1;
        
		$key++;
		last if($key==10);
}


$xls_row=1;
$xls_col=0;

foreach(sort keys %grand_total) {

		$sheet_total->write( $xls_row, $xls_col , $_, $format_detail ); 
		$xls_col += 1;
		$sheet_total->write( $xls_row, $xls_col , $grand_total{$_}{'QTD'}, $format_detail ); 
		$xls_col += 1;
		$sheet_total->write( $xls_row, $xls_col , $grand_total{$_}{'SECONDS'}, $format_detail ); 
		
		$xls_col += 1;
		$sheet_total->write( $xls_row, $xls_col , DateCalcFunctions::seconds_2_hh_mm_str($grand_total{$_}{'SECONDS'}), $format_detail ); 	
		
		$xls_col = 0;
		$xls_row += 1;
        
}

$xls_row=1;
$xls_col=0;

foreach(sort keys %return_codes) {

		$ret_codes->write( $xls_row, $xls_col , $_, $format_detail ); 
		$xls_col += 1;
		$ret_codes->write( $xls_row, $xls_col , $return_codes{$_}, $format_detail ); 		
		
		$xls_col = 0;
		$xls_row += 1;
        
}

$Excelbook->close;

printf("%s\n",$ficheiro);

sub write_header_labels {

	$sheet_header->write(0,0,'SERVER',$format_header);	
	$sheet_header->write(0,1,'JOB_NUMBER',$format_header);
	$sheet_header->write(0,2,'JOB_NAME',$format_header);	
	$sheet_header->write(0,3,'DOMAIN',$format_header);	
	$sheet_header->write(0,4,'CLASS',$format_header);	
	$sheet_header->write(0,5,'STARTED_DATE',$format_header);	
	$sheet_header->write(0,6,'ENDED_DATE',$format_header);	
	$sheet_header->write(0,7,'RUNTIME_SECONDS',$format_header);	
	$sheet_header->write(0,8,'RETURN_CODE',$format_header);			
	$sheet_header->set_column( 0, 0, 10 ); 
	$sheet_header->set_column( 1, 1, 15 ); 
	$sheet_header->set_column( 2, 1, 15 ); 
	$sheet_header->set_column( 3, 3, 10 ); 
	$sheet_header->set_column( 4, 4, 10 ); 	
	$sheet_header->set_column( 5, 5, 20 ); 
	$sheet_header->set_column( 6, 6, 20 ); 	
	$sheet_header->set_column( 7, 7, 20 ); 
	$sheet_header->set_column( 8, 8, 15 ); 		


	$sheet_detail->write(0,0,'STARTED_DATE',$format_header);	
	$sheet_detail->write(0,1,'JOB_NAME',$format_header);
	$sheet_detail->write(0,2,'TOTAL_JOB_RUNS',$format_header);	
	$sheet_detail->write(0,3,'TOTAL_RUNTIME_SECONDS',$format_header);		
	$sheet_detail->set_column( 0, 0, 20 ); 
	$sheet_detail->set_column( 1, 1, 15 ); 
	$sheet_detail->set_column( 2, 1, 20 ); 
	$sheet_detail->set_column( 3, 3, 30 ); 
	
	
	$sheet_trailer->write(0,0,'JOB_NAME',$format_header);
	$sheet_trailer->write(0,1,'TOTAL_JOB_RUNS',$format_header);	
	$sheet_trailer->write(0,2,'TOTAL_RUNTIME_SECONDS',$format_header);		
	$sheet_trailer->set_column( 0, 0, 15 ); 
	$sheet_trailer->set_column( 1, 1, 20 ); 
	$sheet_trailer->set_column( 2, 2, 30 ); 
	
	
	$top10_runs->write(0,0,'JOB_NAME',$format_header);
	$top10_runs->write(0,1,'TOTAL_JOB_RUNS',$format_header);	
	$top10_runs->write(0,2,'TOTAL_RUNTIME_SECONDS',$format_header);	
	$top10_runs->write(0,3,'TOTAL_RUNTIME_HHMM',$format_header);		
	$top10_runs->set_column( 0, 0, 15 ); 
	$top10_runs->set_column( 1, 1, 20 ); 
	$top10_runs->set_column( 2, 2, 30 ); 
	$top10_runs->set_column( 3, 3, 30 ); 
	
	
	$top10_time->write(0,0,'JOB_NAME',$format_header);
	$top10_time->write(0,1,'TOTAL_JOB_RUNS',$format_header);	
	$top10_time->write(0,2,'TOTAL_RUNTIME_SECONDS',$format_header);	
	$top10_time->write(0,3,'TOTAL_RUNTIME_HHMM',$format_header);		
	$top10_time->set_column( 0, 0, 15 ); 
	$top10_time->set_column( 1, 1, 20 ); 
	$top10_time->set_column( 2, 2, 30 ); 
	$top10_time->set_column( 3, 3, 30 ); 
	
	
	$sheet_total->write(0,0,'STARTED_DATE',$format_header);
	$sheet_total->write(0,1,'TOTAL_JOB_RUNS',$format_header);	
	$sheet_total->write(0,2,'TOTAL_RUNTIME_SECONDS',$format_header);	
	$sheet_total->write(0,3,'TOTAL_RUNTIME_HHMM',$format_header);		
	$sheet_total->set_column( 0, 0, 20 ); 
	$sheet_total->set_column( 1, 1, 20 ); 
	$sheet_total->set_column( 2, 2, 30 ); 		
	$sheet_total->set_column( 3, 3, 30 ); 
	
	$ret_codes->write(0,0,'RETURN_CODE',$format_header);		
	$ret_codes->write(0,1,'TOTAL',$format_header);		
	$ret_codes->set_column( 0, 0, 15 ); 
	$ret_codes->set_column( 1, 1, 15 ); 
	
	$error_jobs->write(0,0,'SERVER',$format_header);	
	$error_jobs->write(0,1,'JOB_NUMBER',$format_header);
	$error_jobs->write(0,2,'JOB_NAME',$format_header);	
	$error_jobs->write(0,3,'DOMAIN',$format_header);	
	$error_jobs->write(0,4,'CLASS',$format_header);	
	$error_jobs->write(0,5,'STARTED_DATE',$format_header);	
	$error_jobs->write(0,6,'ENDED_DATE',$format_header);	
	$error_jobs->write(0,7,'RUNTIME_SECONDS',$format_header);	
	$error_jobs->write(0,8,'RETURN_CODE',$format_header);			
	$error_jobs->set_column( 0, 0, 10 ); 
	$error_jobs->set_column( 1, 1, 15 ); 
	$error_jobs->set_column( 2, 1, 15 ); 
	$error_jobs->set_column( 3, 3, 10 ); 
	$error_jobs->set_column( 4, 4, 10 ); 	
	$error_jobs->set_column( 5, 5, 20 ); 
	$error_jobs->set_column( 6, 6, 20 ); 	
	$error_jobs->set_column( 7, 7, 20 ); 
	$error_jobs->set_column( 8, 8, 15 ); 		
	
}


sub getDateRange {

	my $data=shift;
	$data =~ /(\d{2})(\d{2})(\d{2})/;
	
	my $mes = $1;
	my $dia = $2;
	my $ano = $3;
	$ano += 2000;
	
	my $ret = sprintf("%04d%02d%02d",$ano, $mes, $dia);
	($ano, $mes, $dia) = Add_Delta_Days($ano, $mes, $dia, 6);
	
	$ret .= '_' . sprintf("%04d%02d%02d",$ano, $mes, $dia);
	return $ret;
	
}


sub clearDate {

	my $x = shift;	
	$x =~ /(\d{4})(\d{2})(\d{2}) (\d{2})/;

	return (sprintf("%04d-%02d-%02d;%02d" ,$1, $2, $3, $4));

}

sub isReturnCodeError {

	my $entrada = shift;
	
	return 1 if(length($entrada)<5);
	if(length($entrada)==5) {
		return 1 if(substr($entrada,1)>40 or substr($entrada,0,1) ne 'C');
	}

	return 0;
}