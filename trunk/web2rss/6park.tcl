#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/6park

catch {
    file mkdir $datadir
}

#----------------------------------------------------------------------
# Shared scripts [to be moved to separate file]
#----------------------------------------------------------------------

proc wget {url {encoding {utf-8}}} {
    set data ""
    catch {
        set fd [open "|wget -q -O - $url 2> /dev/null"]
        fconfigure $fd -encoding $encoding
        set data [read $fd]
    }
    catch {
        close $fd
    }
    return $data
}

proc makelist {data splitter} {
    regsub -all $splitter $data \uFFFF data
    set list [split $data \uFFFF]
    return [lrange $list 1 end]
}

proc getcachefile {localname} {
    global datadir

    return $datadir/[file tail $localname]
}

proc getfile {link localname {encoding utf-8}} {
    set fname [getcachefile $localname]

    if {![file exists $fname]} {
        set data [wget $link $encoding]
        set fd [open $fname w+]
        fconfigure $fd -encoding $encoding
        puts -nonewline $fd $data
        close $fd
    } else {
        set fd [open $fname]
        fconfigure $fd -encoding $encoding
        set data [read $fd]
        close $fd
    }
    return $data
}

proc makeitem {title link data date} {
    set t {
        <item>
        <title><![CDATA[TITLE]]></title>
        <link>LINK_URL</link>
        <description><![CDATA[DESCRIPTION]]></description>
        <pubDate>DATE</pubDate>
        </item>
    }

    regsub -all TITLE       $t $title t
    regsub -all LINK_URL    $t $link  t
    regsub -all DESCRIPTION $t $data  t
    regsub -all DATE        $t [clock format $date] t
    return $t
}


#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------

proc update {} {
    global datadir

    set out  {<?xml version="1.0" encoding="utf-8"?>

<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">  
  <channel> 
    <title>6park</title>  
    <link>http://6park.com</link>  
    <description>DESC</description>  
    <dc:language>LANG</dc:language>  
    <pubDate>DATE</pubDate>  
    <dc:date>DATE</dc:date>  
    <sy:updatePeriod>hourly</sy:updatePeriod>  
    <sy:updateFrequency>1</sy:updateFrequency>  
    <sy:updateBase>2003-06-01T12:00+09:00</sy:updateBase>  
    }

    set date [clock format [clock seconds]]
    regsub -all DATE        $out $date out
    regsub -all LANG        $out zh    out
    regsub -all DESC        $out 6prk  out

    set data [wget http://www.6park.com/news/multi1.shtml gb2312]

    regsub {.*<td class=td1>} $data "" data
    regsub {</table>.*} $data "" data

    set lastdate 0xffffffff

    foreach line [makelist $data <li>] {
        if {[regexp {href="([^>]+)"} $line dummy link] &&
            [regexp {>([^<]+)<} $line dummy title]} {
            #puts $title==$link
        }

        set fname [getcachefile $link]

        set data [getfile $link [file tail $link] gb2312]
        set date [file mtime $fname]
        if {$date >= $lastdate} {
            set date [expr $lastdate - 1]
        }
        set lastdate $date

        regsub {.*<!--bodybegin-->} $data "" data
        regsub {<!--bodyend-->.*} $data "" data
        regsub -all {<font color=E6E6DD> www.6park.com</font>} $data "\n\n" data
        regsub {.*</script>} $data "" data 
        append out [makeitem $title $link $data $date]

    }

    append out {</channel></rss>}

    set fd [open $datadir.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}

update