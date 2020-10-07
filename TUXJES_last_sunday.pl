

sub get_last_sunday {

	#$JESROOT/jessyslog/jessys.log.<mmddyy>"
	use Date::Calc qw(Add_Delta_Days);
	
	my ($d, $m, $y, $wd) = (localtime())[3..7];	
	$y-=100;
	$m+=1;
	$offset=$wd * (-1);
	my ($y2, $m2, $d2) = Add_Delta_Days($y, $m, $d, $offset);
	
	return (sprintf("jessys.log.%02d%02d%02d\n",$m2, $d2, $y2));

}

print get_last_sunday();