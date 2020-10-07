# TUXJES/lib

## Library support files

Various files (perl PM files) with functions that are used by other perl scripts. This way there is no copy & paste of functions and in case that there is a need to fix, it is better in one place and not scattered on many files.

* **DateCalcFunctions.pm**
	+ getWeekday 
	+ converteData2PowerBI 
	+ getYesterday 
	+ getYesterdayYYYYMMDD 
	+ getYesterdayYYYY_MM_DD 
	+ get_seconds_work_time 
	+ get_total_work_time 
	+ time_2_seconds 
	+ seconds_2_time 
	+ seconds_2_hh_mm 
	+ seconds_2_hh_mm_str 
	+ valida_tempos 
	+ muda_espaco_data_hora 
	+ getLocaltime 
	+ getCurrentDate 
	+ getCurrentDateYYYYMMDD 
	+ getCurrentHourHH 
	+ getCurrenttime 
	+ data_hora 
    
    
* **DateFunctions.pm**
	+ getLocaltime 
	+ getCurrentDate 
	+ getCurrentDateYYYYMMDD 
	+ getCurrentHourHH 
	+ getCurrenttime 


* **FileFunctions.pm**
	+ getFileName 
	+ getFileNameSize 


* **LogScrapperFunctions.pm**
	+ converteFormatoData 
	+ getCurrentDateTime 
	+ getCurrentDate 
	+ getCurrentTime 
	+ sendEmergencyEMAIL 


* **scrapper_backup.pm**
	+ create_backup_file 


* **scrapper_library.pm**
	+ get_data_AAAAMM 


* **TuxjesLogDate.pm**
	+ getTuxjesLogDate  [**OUT** (Returns the date of the current jessys.log file name, that is MMDDYY, of the **last** Sunday, that is when the log file rotates)]       


* **tuxjes_current_log_running.pm**
	+ getCurrentLogName


* **WorktimeFunction.pm**
	+ getWorkTimeInSeconds [**IN** (YYYYMMDD HH:MM:SS, YYYYMMDD HH:MM:SS) **OUT** (number of seconds between the two dates)]
    
    



