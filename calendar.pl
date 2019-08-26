#!"C:\xampp\perl\bin\perl.exe"
#use warnings;
# use strict;
use CGI;
use Encode;
use UTF8;
use MIME::Base64::Perl;
use Net::XMPP;
# qw( :standard );

package CALENDAR;

# +-------------------------------------------------------------------+
# |                 H T M L - C A L E N D A R   (v2.15)               |
# |                                                                   |
# | Copyright Gerd Tentler                www.gerd-tentler.de/tools   |
# | Created: May 27, 2003                 Last modified: Apr. 2, 2011 |
# +-------------------------------------------------------------------+
# | This program may be used and hosted free of charge by anyone for  |
# | personal purpose as long as this copyright notice remains intact. |
# |                                                                   |
# | Obtain permission before selling the code for this program or     |
# | hosting this software on a commercial website or redistributing   |
# | this software over the Internet or in any other medium. In all    |
# | cases copyright must remain intact.                               |
# +-------------------------------------------------------------------+
#
# EXAMPLE #1:  $myCal = CALENDAR->new();
#              print $myCal->create();
#
# EXAMPLE #2:  $myCal = CALENDAR->new(2004, 12);
#              print $myCal->create();
#
# EXAMPLE #3:  $myCal = CALENDAR->new();
#              $myCal->{year} = 2004;
#              $myCal->{month} = 12;
#              print $myCal->create();
#
# Returns HTML code
#=========================================================================================================

my $cal_ID = 0;

sub initialize {
	my $this = shift;
#---------------------------------------------------------------------------------------------------------
# Configuration
#---------------------------------------------------------------------------------------------------------
	$this->{tFontFace} = 'Arial, Helvetica';	# title: font family (CSS-spec, e.g. "Arial, Helvetica")
	$this->{tFontSize} = 14;					# title: font size (pixels)
	$this->{tFontColor} = '#FFFFFF';			# title: font color
	$this->{tBGColor} = '#304B90';				# title: background color

	$this->{hFontFace} = 'Arial, Helvetica';	# heading: font family (CSS-spec, e.g. "Arial, Helvetica")
	$this->{hFontSize} = 12;					# heading: font size (pixels)
	$this->{hFontColor} = '#FFFFFF';			# heading: font color
	$this->{hBGColor} = '#304B90';				# heading: background color

	$this->{dFontFace} = 'Arial, Helvetica';	# days: font family (CSS-spec, e.g. "Arial, Helvetica")
	$this->{dFontSize} = 14;					# days: font size (pixels)
	$this->{dFontColor} = '#000000';			# days: font color
	$this->{dBGColor} = '#FFFFFF';				# days: background color

	$this->{wFontFace} = 'Arial, Helvetica';	# weeks: font family (CSS-spec, e.g. "Arial, Helvetica")
	$this->{wFontSize} = 12;					# weeks: font size (pixels)
	$this->{wFontColor} = '#FFFFFF';			# weeks: font color
	$this->{wBGColor} = '#304B90';				# weeks: background color

	$this->{saFontColor} = '#A00000';			# Saturdays: font color
	$this->{saBGColor} = '#FFF0F0';				# Saturdays: background color

	$this->{suFontColor} = '#D00000';			# Sundays: font color
	$this->{suBGColor} = '#FFF0F0';				# Sundays: background color

	$this->{tdBorderColor} = '#FF0000';			# today: border color

	$this->{borderColor} = '#304B90';			# border color
	$this->{hilightColor} = '#FFFF00';			# hilight color (works only in combination with link)

	$this->{link} = '';							# page to link to when day is clicked
	$this->{linkTarget} = '';					# link target frame or window, e.g. parent.myFrame
	$this->{offset} = 2;						# week start: 0 - 6 (0 = Saturday, 1 = Sunday, 2 = Monday ...)
	$this->{weekNumbers} = 1;					# view week numbers: 1 = yes, 0 = no

#---------------------------------------------------------------------------------------------------------
# You should change these variables only if you want to translate them into your language:
#---------------------------------------------------------------------------------------------------------
	# weekdays: must start with Saturday because January 1st of year 1 was a Saturday
	@{$this->{weekdays}} = ("—Ѕ", "¬—", "ѕн", "¬т", "—р", "„т", "ѕт");

	# months: must start with January
	@{$this->{months}} = ("январь", "‘евраль", "ћарт", "јпрель", "ћай", "»юнь", "»юль", "јвгуст", "—ент€брь", "ќкт€брь", "Ќо€брь", "ƒекабрь");

	# error messages
	@{$this->{error}} = ("Year must be 1 - 3999!", "Month must be 1 - 12!");

#---------------------------------------------------------------------------------------------------------
# Don't change from here:
#---------------------------------------------------------------------------------------------------------
	$this->{year} = 0;
	$this->{month} = 0;
	$this->{week} = 0;
	$this->{size} = 0;
	@{$this->{mDays}} = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
	%{$this->{specDays}} = {};
}

sub new {
	my $year = $_[1];
	my $month = $_[2];
	my $week = $_[3];
	my $self = {};
	bless $self;
	$self->initialize();
	if($year eq '' && $month eq '') {
		my ($sec, $min, $hr, $day, $m, $y, $wday, $yday, $stime) = localtime(time);
		$year = $y + 1900;
		$month = $m + 1;
	}
	elsif($year ne '' && $month eq '') { $month = 1; }
	$self->{year} = $year;
	$self->{month} = $month;
	$self->{week} = $week;
	if($self->{linkTarget} eq '') { $self->{linkTarget} = 'document'; }
	return $self;
}

sub set_styles {
	my $this = shift;
	my $html;

	$cal_ID++;
	$html = '<style> .cssTitle' . $cal_ID . ' { ';
	if($this->{tFontFace}) { $html .= 'font-family: ' . $this->{tFontFace} . '; '; }
	if($this->{tFontSize}) { $html .= 'font-size: ' . $this->{tFontSize} . 'px; '; }
	if($this->{tFontColor}) { $html .= 'color: ' . $this->{tFontColor} . '; '; }
	if($this->{tBGColor}) { $html .= 'background-color: ' . $this->{tBGColor} . '; '; }
	$html .= '} .cssHeading' . $cal_ID . ' { ';
	if($this->{hFontFace}) { $html .= 'font-family: ' . $this->{hFontFace} . '; '; }
	if($this->{hFontSize}) { $html .= 'font-size: ' . $this->{hFontSize} . 'px; '; }
	if($this->{hFontColor}) { $html .= 'color: ' . $this->{hFontColor} . '; '; }
	if($this->{hBGColor}) { $html .= 'background-color: ' . $this->{hBGColor} . '; '; }
	$html .= '} .cssDays' . $cal_ID . ' { ';
	if($this->{dFontFace}) { $html .= 'font-family: ' . $this->{dFontFace} . '; '; }
	if($this->{dFontSize}) { $html .= 'font-size: ' . $this->{dFontSize} . 'px; '; }
	if($this->{dFontColor}) { $html .= 'color: ' . $this->{dFontColor} . '; '; }
	if($this->{dBGColor}) { $html .= 'background-color: ' . $this->{dBGColor} . '; '; }
	$html .= '} .cssWeeks' . $cal_ID . ' { ';
	if($this->{wFontFace}) { $html .= 'font-family: ' . $this->{wFontFace} . '; '; }
	if($this->{wFontSize}) { $html .= 'font-size: ' . $this->{wFontSize} . 'px; '; }
	if($this->{wFontColor}) { $html .= 'color: ' . $this->{wFontColor} . '; '; }
	if($this->{wBGColor}) { $html .= 'background-color: ' . $this->{wBGColor} . '; '; }
	$html .= '} .cssSaturdays' . $cal_ID . ' { ';
	if($this->{dFontFace}) { $html .= 'font-family: ' . $this->{dFontFace} . '; '; }
	if($this->{dFontSize}) { $html .= 'font-size: ' . $this->{dFontSize} . 'px; '; }
	if($this->{saFontColor}) { $html .= 'color: ' . $this->{saFontColor} . '; '; }
	if($this->{saBGColor}) { $html .= 'background-color: ' . $this->{saBGColor} . '; '; }
	$html .= '} .cssSundays' . $cal_ID . ' { ';
	if($this->{dFontFace}) { $html .= 'font-family: ' . $this->{dFontFace} . '; '; }
	if($this->{dFontSize}) { $html .= 'font-size: ' . $this->{dFontSize} . 'px; '; }
	if($this->{suFontColor}) { $html .= 'color: ' . $this->{suFontColor} . '; '; }
	if($this->{suBGColor}) { $html .= 'background-color: ' . $this->{suBGColor} . '; '; }
	$html .= '} .cssHilight' . $cal_ID . ' { ';
	if($this->{dFontFace}) { $html .= 'font-family: ' . $this->{dFontFace} . '; '; }
	if($this->{dFontSize}) { $html .= 'font-size: ' . $this->{dFontSize} . 'px; '; }
	if($this->{dFontColor}) { $html .= 'color: ' . $this->{dFontColor} . '; '; }
	if($this->{hilightColor}) { $html .= 'background-color: ' . $this->{hilightColor} . '; '; }
	$html .= 'cursor: default; ';
	$html .= '} </style>';

	return $html;
}

sub leap_year {
	my ($this, $year) = @_;
	return (!($year % 4) && ($year < 1582 || $year % 100 || !($year % 400))) ? 1 : 0;
}

sub get_weekday {
	my ($this, $year, $days) = @_;
	my $i;
	my $a = $days;

	if($year) { $a += ($year - 1) * 365; }
	for($i = 1; $i < $year; $i++) { if($this->leap_year($i)) { $a++; }}
	if($year > 1582 || ($year == 1582 && $days > 277)) { $a -= 10; }
	if($a) { $a = ($a - $this->{offset}) % 7; }
	elsif($this->{offset}) { $a += 7 - $this->{offset}; }

	return $a;
}

sub get_week {
	my ($this, $year, $days) = @_;
	my $firstWDay = $this->get_weekday($year, 0);
	if($year == 1582 && $days > 277) { $days -= 10; }

	return int(($days + $firstWDay) / 7) + ($firstWDay <= 3);
}

sub table_cell {
	my ($this, $content, $class, $date, $style) = @_;
	my ($size, $html, $link, $bgColor, @events);

	$size = _round($this->{size} * 1.5);
	$html = '<td align=center width=' . $size . ' class="' . $class . '"';

	if($content ne '&nbsp;' && $class =~ m/day/i) {
		$link = $this->{link};

		if($this->{specDays}{$content}) {
			foreach (@{$this->{specDays}{$content}}) {
				if(@{$_}[0]) { $bgColor = @{$_}[0]; }
				if(@{$_}[1]) { push(@events, @{$_}[1]); }
				if(@{$_}[2]) { $link = @{$_}[2]; }
			}
			$html .= ' title="' . join(' &middot; ', @events) . '"';
			if($bgColor) { $style .= 'background-color:' . $bgColor . ';' };
		}
		if($link) {                     
			$link .= ($link =~ /\?/) ? "&date=$date" : "?date=$date";
			$html .= ' onMouseOver="this.className=\'cssHilight' . $cal_ID . '\'"';
			$html .= ' onMouseOut="this.className=\'' . $class . '\'"';
#			$html .= ' onClick="' . $this->{linkTarget} . '.location.href=\'' . $link . '\'"';
		      $html .= ' onClick="' . 'top.location.href=\'' . $link . '\'"' .' target="_top"';
		
	}
	}
	if($style) { $html .= ' style="' . $style . '"'; }
	$html .= '>' . $content . '</td>';

	return $html;
}

sub table_head {
	my ($this, $content) = @_;
	my ($html, $i, $ind, $wDay);
	my $cols = $this->{weekNumbers} ? 8 : 7;

	$html = '<tr><td colspan=' . $cols . ' class="cssTitle' . $cal_ID . '" align=center><b>' .
			$content . '</b></td></tr><tr>';
	for($i = 0; $i < int @{$this->{weekdays}}; $i++) {
		$ind = ($i + $this->{offset}) % 7;
		$wDay = $this->{weekdays}[$ind];
		$html .= $this->table_cell($wDay, 'cssHeading' . $cal_ID);
	}
	if($this->{weekNumbers}) { $html .= $this->table_cell('&nbsp;', 'cssHeading' . $cal_ID); }
	$html .= '</tr>';

	return $html;
}

sub viewEvent {
	my ($this, $from, $to, $color, $title, $link) = @_;

	if($from > $to) { return; }
	if($from < 1 || $from > 31) { return; }
	if($to < 1 || $to > 31) { return; }

	while($from <= $to) {
		if(!$this->{specDays}{$from}) { @{$this->{specDays}{$from}} = (); }
		push(@{$this->{specDays}{$from}}, [$color, $title, $link]);
		$from++;
	}
}

sub viewEventEach {
	my ($this, $weekday, $color, $title, $link) = @_;
	my ($i, $days, $start);

	if($weekday < 0 || $weekday > 6) { return; }
	for($i = $days = 0; $i < $this->{month} - 1; $i++) { $days += $this->{mDays}[$i]; }

	for($i = 0; $i < $this->{mDays}[$this->{month}-1]; $i++) {
		if($this->get_weekday($this->{year}, $days + $i) == $weekday - $this->{offset} + 1) {
			if(!$this->{specDays}{$i}) { @{$this->{specDays}{$i}} = (); }
			push(@{$this->{specDays}{$i}}, [$color, $title, $link]);
		}
	}
}

sub create {
	my $this = shift;
	my ($html, $i, $start, $stop, $title, $daycount, $inThisMonth);
	my ($days, $weekNr, $ind, $class, $style, $content, $date);
	my ($sec, $min, $hr, $curDay, $curMonth, $curYear, $wday, $yday, $stime) = localtime(time);

	$curYear += 1900;
	$curMonth += 1;

	$this->{size} = ($this->{hFontSize} > $this->{dFontSize}) ? $this->{hFontSize} : $this->{dFontSize};
	if($this->{wFontSize} > $this->{size}) { $this->{size} = $this->{wFontSize}; }

	if($this->{year} < 1 || $this->{year} > 3999) { $html = '<b>' . $this->{error}[0] . '</b>'; }
	elsif($this->{month} < 1 || $this->{month} > 12) { $html = '<b>' . $this->{error}[1] . '</b>'; }
	else {
		$this->{mDays}[1] = $this->leap_year($this->{year}) ? 29 : 28;
		for($i = $days = 0; $i < $this->{month} - 1; $i++) { $days += $this->{mDays}[$i]; }

		$start = $this->get_weekday($this->{year}, $days);
		$stop = $this->{mDays}[$this->{month}-1];

		$html = $this->set_styles();
		$html .= '<table border=0 cellspacing=0 cellpadding=0><tr>';
		$html .= '<td' . ($this->{borderColor} ? ' bgcolor=' . $this->{borderColor}	: '') . '>';
		$html .= '<table border=0 cellspacing=1 cellpadding=3>';
		$title = $this->{months}[$this->{month}-1] . ' ' . $this->{year};
		$html .= $this->table_head($title);
		$daycount = 1;

		if(($this->{year} == $curYear) && ($this->{month} == $curMonth)) { $inThisMonth = 1; }
		else { $inThisMonth = 0; }

		if($this->{weekNumbers} || $this->{week}) { $weekNr = $this->get_week($this->{year}, $days); }

		while($daycount <= $stop) {
			if($this->{week} && $this->{week} != $weekNr) {
				$daycount += 7 - ($daycount == 1 ? $start : 0);
				$weekNr++;
				next;
			}
			$html .= '<tr>';

			for($i = $wdays = 0; $i <= 6; $i++) {
				$ind = ($i + $this->{offset}) % 7;
				if($ind == 0) { $class = 'cssSaturdays'; }
				elsif($ind == 1) { $class = 'cssSundays'; }
				else { $class = 'cssDays'; }

				$style = '';
				$date = sprintf('%4d-%02d-%02d', $this->{year}, $this->{month}, $daycount);

				if(($daycount == 1 && $i < $start) || $daycount > $stop) { $content = '&nbsp;'; }
				else {
					$content = $daycount;
					if($inThisMonth && $daycount == $curDay) {
						$style = 'padding:0px;border:3px solid ' . $this->{tdBorderColor} . ';';
					}
					elsif($this->{year} == 1582 && $this->{month} == 10 && $daycount == 4) { $daycount = 14; }
					$daycount++;
					$wdays++;
				}
				$html .= $this->table_cell($content, $class . $cal_ID, $date, $style);
			}

			if($this->{weekNumbers}) {
				if(!$weekNr) {
					if($this->{year} == 1) { $content = '&nbsp;'; }
					elsif($this->{year} == 1583) { $content = 51; }
					else { $content = $this->get_week($this->{year} - 1, 365); }
				}
				elsif($this->{month} == 12 && $weekNr >= 52 && $wdays < 4) { $content = 1; }
				else { $content = $weekNr; }

				$html .= $this->table_cell($content, 'cssWeeks' . $cal_ID);
				$weekNr++;
			}
			$html .= '</tr>';
		}
		$html .= '</table></td></tr></table>';
	}
	return $html;
}

#---------------------------------------------------------------------------------------------------------
# PRIVATE
#---------------------------------------------------------------------------------------------------------

sub _round {
	my $fl = shift;
	return ($fl >= 0) ? int($fl + 0.5) : int($fl - 0.5);
}

#TestLine='јаЅб¬в√гƒд≈е®Є∆ж«з»и…й кЋлћмЌнќоѕп–р—с“т”у‘ф’х÷ц„чЎшўщЏъџы№ьЁэёюя€';

# print &TranslateWin1251ToUni($TestLine)."\n";

sub TranslateWin1251ToUni{
         my @ChArray=split('',$_[0]);
         my $Unicode='';
         my $Code='';
         for(@ChArray){
                 $Code=ord;
                 if(($Code>=0xc0)&&($Code<=0xff)){$Unicode.="&#".(0x350+$Code).";";}
                 elsif($Code==0xa8){$Unicode.="&#".(0x401).";";}
                 elsif($Code==0xb8){$Unicode.="&#".(0x451).";";}
                 else{$Unicode.=$_;}}
         return $Unicode;
}


sub to_utf8
{
my $data = shift();
my $charset = shift();

my $ref = ref( $data );
require Encode;

if( $ref eq 'SCALAR' )
{
## no critic Subroutines::ProtectPrivateSubs
Encode::_utf8_off( ${$data} );
Encode::from_to( ${$data}, $charset, 'utf8' );
Encode::_utf8_on( ${$data} );
## use critic Subroutines::ProtectPrivateSubs
}
elsif( $ref eq 'HASH' )
{
foreach my $value ( values( %{$data} ) )
{
next() unless defined( $value );
to_utf8( ref( $value ) ? $value : \$value, $charset );
}
}
elsif( $ref eq 'ARRAY' )
{
foreach my $value ( @{$data} )
{
next() unless defined( $value );
to_utf8( ref( $value ) ? $value : \$value, $charset );
}
}

return;
}



#---------------------------------------------------------------------------------------------------------

         my @timeParts=localtime; 

	 my ($my_day, $my_month, $my_year) = ($timeParts[3],$timeParts[4],$timeParts[5]); 
 	 $my_year+=1900;       $my_month++;
	if  (length(CGI::param ("date"))>0){
		$my_year=substr(CGI::param ("date"),0,4);
		$my_month=substr(CGI::param ("date"),5,2);
		$my_day=substr(CGI::param ("date"),8,2);

	}
        $myCGI = new CGI;
	my $data = CGI::param ("HIDDEN");
	my $comment =  CGI::param("COMMENT");
	$data .= "$comment";

#	print $myCGI->header();
      print  "Content-type: text/html; charset=windows-1251\n\n";
      print $myCGI->start_html(-lang=>'ru-RU', -encoding=>"windows-1251", -charset=>"windows-1251",-title=>"registry for ar");
#				-header=>"Content-type: text/html; charset=windows-1251\n\n");	

#  за " . $my_month . "." . $my_year
#		 print "$my_year.$my_month.$my_day";
	$myCal = CALENDAR->new($my_year, $my_month);

	for ($i=1;$i< 32;++$i){
		$file = "c:/xampp/htdocs/".$my_year."-".(sprintf "%02d",$my_month)."-" . (sprintf "%02d",$i) .".htm";
		if ( -e $file){
  		 $myCal->viewEvent($i, $i, "#D0FFD0", "–еестр", "./index.pl");#?date=".$my_year."-".$my_month."-" . $i ); 
	 }
	}
	($my_fmonth,$my_fyear) = ($my_month, $my_year);
	if ($my_day > 27|| $my_day < 5 ) {  
	if ($my_day > 27){
		if  ($my_month == 12){ $my_year++; $my_month = 1;}
		else { $my_month++;}}
	if ($my_day < 5){	
		if  ($my_month == 1){ $my_year--; $my_month = 12;}
		else { $my_month--;}}

	  $myCal2 = CALENDAR->new($my_year, $my_month);
	  for ($i=1;$i< 32;++$i){

		$file = "c:/xampp/htdocs/".$my_year."-".(sprintf "%02d",$my_month)."-" . (sprintf "%02d",$i) .".htm";
		if ( -e $file){
	 	 $myCal2->viewEvent($i, $i, "#D0FFD0", "–еестр", "./index.pl");#?date=".$my_year."-".$my_month."-" . $i ) ;
	   }
	     
	   }

	}
	if ($my_month==$my_fmonth){
         print $myCal->create();
       } 
	elsif ($my_month < $my_fmonth || $my_year < $my_fyear){
            print $myCal2->create();
            print $myCal->create();
	} 
	else {
            print $myCal->create();
            print $myCal2->create();
	}

#          print "<HTML>\n";
#          print "<BODY>\n";

#	  print "</BODY>\n";
#          print "</HTML>\n";
	$comment = $myCGI->param("COMMENT");


print $myCGI->hr; 

my $mydate=	CGI::param("date");
  if (CGI::param("date")) {
   	  $myfile = "c:/xampp/htdocs/".  CGI::param("date") .".txt";
       if (-e  $myfile) {
        open (CHECKBOOK, $myfile);

	while ($record = <CHECKBOOK>) {

#  	 Encode::from_to($record, 'utf-8', 'windows-1251');
 	  print $record;
	}
	close(CHECKBOOK);
 }   
}    

$name = CGI::cookie("name");
#print CGI::p("name=$name");
#print CGI::p("name=$name");
 	print <<Form if ($name eq 'admin' || $name eq 'boss');
<script type="text/javascript">
var t_o=0;
var dirty=false;
function I(e){
	return document.getElementById(e);
}
/**
     * Get a cookie.
     */
    function getC(name) {
        var cookie = document.cookie, e, p = name + "=", b;

        if ( !cookie )
            return;

        b = cookie.indexOf("; " + p);

        if ( b == -1 ) {
            b = cookie.indexOf(p);

            if ( b != 0 )
                return null;

        } else {
            b += 2;
        }

        e = cookie.indexOf(";", b);

        if ( e == -1 )
            e = cookie.length;

        return decodeURIComponent( cookie.substring(b + p.length, e) );
    };

    /**
     * Set a cookie.
     *
     * The 'expires' arg can be either a JS Date() object set to the expiration date (back-compat)
     * or the number of seconds until expiration
     */
    function setC(name, value, expires, path, domain, secure) {
        var d = new Date();

        if ( typeof(expires) == 'object' && expires.toGMTString ) {
            expires = expires.toGMTString();
        } else if ( parseInt(expires, 10) ) {
            d.setTime( d.getTime() + ( parseInt(expires, 10) * 1000 ) ); // time must be in miliseconds
            expires = d.toGMTString();
        } else {
            expires = '';
        }

        document.cookie = name + "=" + encodeURIComponent(value) +
            ((expires) ? "; expires=" + expires : "") +
            ((path) ? "; path=" + path : "") +
            ((domain) ? "; domain=" + domain : "") +
            ((secure) ? "; secure" : "");
    }

function startTimer(){
	dirty=true;
	t_o=setTimeout(saveIt,1000);
}
function stopTimer(){
	saveIt();
	if(t_o) clearTimeout(to);
	t_o=0;
}
function saveIt(){
	var t=I("comment");
	setC('resol',t.value,24*3600,'/');
}
function loadIt(){
	var t=I("comment");
	var v=getC('resol');
	if(v)
		t.value=v;
}
function clearDirty(){
	dirty=false;
}
</script>
	<form method = "post" action = "./calendar.pl?date=$mydate">
	<strong> –еестр за $mydate </strong>  
	<TEXTAREA cols=21 rows=20 id="comment" name = "COMMENT" onkeypress="startTimer()" onblur="stopTimer()">
	 –езолюци€ </TEXTAREA>
	 <br>
	<input type= "HIDDEN" name = "HIDDEN" value = "$data">
	<input type= "SUBMIT"  value = "подписать" onclick="clearDirty()">
	</form>

<script type="text/javascript">
	loadIt();
	dirty=false;

	document.body.onbeforeunload=function(){
		if(dirty) return "–езолюци€ не отправлена, выйти?";
		else return null;
	};
</script>


Form
	
#	print (CGI::p($data));
        
	if (length($data) > 0){
		open (CHECKBOOK, ">>".$myfile);	
		print CHECKBOOK  (CGI::h2($data));	close CHECKBOOK;
#		$msg_body=MIME::Base64::Perl::encode_base64("–езолюци€ на реестр за" . $mydate . "\n" . $data); 
#		$msg_body =Encode::from_to("–езолюци€ на реестр за" . $mydate . "\n" . $data, "windows1251", "utf-8");
		$msg_body ="–езолюци€ на реестр за" . $mydate . "\n" . $data;
		$msg_subj ="–езолюци€ на реестр за" . $mydate;
		to_utf8( \$msg_body, 'windows-1251' );
		to_utf8( \$msg_subj, 'windows-1251' );


#		$msg_body =TranslateWin1251ToUni($msg_body);

                $con=new Net::XMPP::Client();
		$con->Connect(hostname=>"evrasia.ufanet.ru");
		$con->AuthSend(username=>"registry",
                        password=>"reg0809",
                        resource=>"Registry");
		my $msg=new Net::XMPP::Message();
		$msg->SetMessage(to=>"sveta\@evrasia.ufanet.ru",
                from=>"registry\@evrasia.ufanet.ru",
	        subject=>$msg_subj,
                body=>$msg_body);
		$con->Send($msg);
		my $recepient="ирина\@evrasia.ufanet.ru";
		to_utf8(\$recepient, 'windows-1251');
		$msg->SetMessage(to=>$recepient,
                from=>"registry\@evrasia.ufanet.ru",
	        subject=>$msg_subj,
                body=>$msg_body);
		$con->Send($msg);
        	$con->Disconnect();

                open (CHECKBOOK, $myfile);

		while ($record = <CHECKBOOK>) {

		#  	 Encode::from_to($record, 'utf-8', 'windows-1251');
	 	  print $record;
		}
		close(CHECKBOOK);


	}

	




		

print CGI::end_html();



# return 1;
