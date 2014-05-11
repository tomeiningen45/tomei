#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/fortune
catch {
    file mkdir $datadir
}

source $instdir/rss.tcl

set site(lang)     en
set site(encoding) utf-8
set site(desc)     Fortune
set site(url)      http://money.cnn.com/magazines/fortune/

#----------------------------------------------------------------------
# To Move to RSS
#----------------------------------------------------------------------
proc generic_news_site {list_proc parse_proc} {
    global datadir env site

    set out  {<?xml version="1.0" encoding="utf-8"?>

<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">  
  <channel> 
    <title>DESC</title>  
    <link>URL</link>  
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
    regsub -all LANG        $out site(lang)  out
    regsub -all DESC        $out $site(desc) out
    regsub -all URL         $out $site(url)  out

    set max 50
    catch {
        set max $env(MAXRSS)
    }
    set n 0
    set lastdate 0xffffffff

    foreach article [$list_proc] {
        incr n
        if {$n > $max} {
            break
        }
        set link [lindex $article 0]
        set id   [lindex $article 1]

        set fname [getcachefile $id]

        set data [getfile $link [file tail $fname] $site(encoding)]
        set date [file mtime $fname]
        if {$date >= $lastdate} {
            set date [expr $lastdate - 1]
        }
        set lastdate $date

        set item [$parse_proc $data]
        set title [lindex $item 0]
        set data  [lindex $item 1]

        puts $link=$id=$title

        set data "<div lang=\"$site(lang)\" xml:lang=\"$site(lang)\">$data</div>"
        append out [makeitem $title $link $data $date]
    }

    append out {</channel></rss>}

    set fd [open $datadir.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------

proc fortune_get_articles {} {
    global site
    set data [wget $site(url)]
    set list ""
    foreach item [makelist $data "href=\"http://"] {
        #puts $item
        if {[regexp "^(((tech)|(finance)|(management)).fortune.cnn.com/20../../../\[^>\]+/)\"" $item dummy link]} {
            if {![info exists seen($link)]} {
                set seen($link) 1
                lappend list [list "http://$link" [file tail $link]]
            }
        }
    }

    return $list
}



proc fortune_parse_article {data} {
    set title notitle

    if {![regexp {<h1>([^<]+)</h1>} $data dummy title]} {
        regexp {<title>([^<]+)</title>} $data dummy title
    }


    if {[regsub {.*<div id="storytext">} $data "" data] &&
        [regsub {<div class="taglist">Posted in:.*} $data "" data]} {

    } else {
        set data ""
        set title "@@$title"
    }

    return [list $title $data]
}


generic_news_site fortune_get_articles fortune_parse_article




