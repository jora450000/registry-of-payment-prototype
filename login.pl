#!perl
use CGI qw( :standard );
use Digest::MD5;
$name = param( NAME );
#  $Password = param( PASS );

$Password = Digest::MD5::md5_hex( param("PASS") );

$expires = "Monday, 31-DEC-15 23:59:59 GMT";

#print "Set-Cookie: Name=$name; expires=$expires; path=\n";
#print "Set-Cookie: Password=$Password; expires=$expires; path=\n";

$query = new CGI;
$cookie = $query->cookie(-name=>'name',
			 -value=>$name,
			 -expires=>'+500h',
			 -path=>'/');

$cookie1 = $query->cookie(-name=>'password',
			 -value=>$Password,
			 -expires=>'+500h',
			 -path=>'/');

open PASSFILE, "+<c:/xampp/shadow";
while ($record=<PASSFILE>)
{
	if (~ m/($name):*/ && (length($name)+34 == length($record))) {
# затирать пароль	убрать комменты
#			seek(PASSFILE,-33,1); 
# 			print PASSFILE  $Password;			
#
			close PASSFILE;
	};	
}
close PASSFILE;
	
print header(-cookie=>[$cookie1,$cookie], -charset=>"windows-1251"); 
print start_html(-lang=>'ru-RU', -encoding=>"windows-1251", -charset=>"windows-1251",-title=>"Авторизация произведена");
print <<End_Data;
Получены следующие данные:<BR><BR>
<FONT>Имя:</FONT> $name <BR>
<FONT>Пароль:</FONT> *************<BR>
<A HREF = "index.pl">начать работу</A>
	<script language="javascript" type="text/javascript">
	document.location="index.pl";
	</script>

End_Data

print end_html;

   
