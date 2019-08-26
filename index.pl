#!/usr/bin/perl
use CGI qw/:standard :netscape/;
use CGI::Carp;

sub currentDate { 
    my @timeParts=localtime; 
    my ($day, $month, $year) = ($timeParts[3],$timeParts[4],$timeParts[5]); 
    return ($year+1900). "-".($month+1)."-".$day; 
} 
  


#print header();
# start_html("REGISTRY of payments");

$name = CGI::cookie("name");

$password = CGI::cookie("password"); 
unless (CGI::param("password") eq "" )
{
	$password = CGI::param("password");
	$name = CGI::param("name");

}


$query = new CGI;
$cookie = $query->cookie(-name=>'name',
			 -value=>$name,
			 -expires=>'+500h',
			 -path=>'/');

$cookie1 = $query->cookie(-name=>'password',
			 -value=>$password,
			 -expires=>'+500h',
			 -path=>'/');



open PASSFILE, "<c:/xampp/shadow";
open AUTHFILE, ">>c:/xampp/authorize.log";
open LASTFILE, "<c:/xampp/last.txt";
while ($record=<LASTFILE>){
 $mydate=$record;
}
close LASTFILE ;

$host=$ENV{'REMOTE_ADDR'};
$my_time =localtime;
$autorize=0;
$mydate = CGI::param("date") unless (CGI::param("date") eq "");
                                                     

print AUTHFILE "$my_time host = $host  name = $name  dateview=$mydate  ";
while ($record=<PASSFILE>)
{

	if ($record=~ m/($name):(\S+)/ ) { 
		  if (($2 eq $password) && (length($record)==(length($name)+34) ) ){
			$autorize=1;

			print AUTHFILE "logon success \n";
		  } 
	};	
}
close PASSFILE;

	
if ($autorize==0){
	print AUTHFILE "logon failed \n";
	close AUTHFILE;
	print  "Content-type: text/html; charset=windows-1251\n\n";

	print <<REDIRECT;
	<html>
	<head>
	<meta http-equiv="Refresh" content="1;URL="login.html">
	</head>
	<body>
	<script language="javascript" type="text/javascript">
	document.location="login.html";
	</script>
	</body>
	</html> 
REDIRECT
	exit 1;
}


# print CGI::header(-cookie=>[$cookie1,$cookie], -charset=>"windows-1251");
print "Set-Cookie:$cookie\n"; 
print "Set-Cookie:$cookie1\n";

print  "Content-type: text/html; charset=windows-1251\n\n";

print "<HTML><body class='main' style='min-width:1280px'>\n";

print  "<style>\n";
print  "body.main {width:auto; overflow:auto; }\n";
print  "div, iframe {margin:0 }\n";
print  "</style>\n";


close AUTHFILE;


if (length($mydate)==0){
	 $mydate=currentDate;
}


if (-e	"c:/xampp/htdocs/".$mydate.".htm") {
	$myfile ='./'.  $mydate .'.htm';
}else{
	$myfile = "./noregistry.htm";
}

print <<EOF;
  <div style="position:absolute; left:0;top:0; height:97% ">       	
	<iframe src="./calendar.pl?date=$mydate" name="menu" scrolling=0 style="width:210px; overflow:hidden;height:100%">плавающие фреймы не поддерживаются браузером</iframe>
  </div>

  <div style="position:absolute;  height:97%; left:212px; top:0; width:100% ">
       	 <iframe src=$myfile name="main" scrolling=1 style="width:120%;height:740%; border: solid 1px #eee; overflow-x:hidden;">плавающие фреймы не поддерживаются браузером</iframe>
  </div>
EOF

print "</HTML>";