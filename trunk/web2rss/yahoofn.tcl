#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/yahoofn
catch {
    file mkdir $datadir
}

source $instdir/rss.tcl

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------

proc update {} {
    global datadir argv env map

    set name [lindex $argv 0]
    set title [lindex $argv 1]
    set url [lindex $argv 2]

    set out  {<?xml version="1.0" encoding="utf-8"?>

<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">  
  <channel> 
    <title>TITLE</title>  
    <link>http://finance.yahoo.com/news/</link>  
    <description>DESC</description>  
    <pubDate>DATE</pubDate>  
    <dc:date>DATE</dc:date>  
    <sy:updatePeriod>hourly</sy:updatePeriod>  
    <sy:updateFrequency>1</sy:updateFrequency>  
    <sy:updateBase>2003-06-01T12:00+09:00</sy:updateBase>  
    }

    regsub -all & $title "\\\\&amp;" tit
    set tit "YH / $tit"
    puts "   >>>>>>>>>>> Syncing $name == $tit"
    set date [clock format [clock seconds]]
    regsub -all DATE        $out $date  out
    regsub -all DESC        $out $tit out
    regsub -all TITLE       $out $tit out

foreach item $map {
    set name [lindex $item 0]
    set title [lindex $item 1]
    set url [lindex $item 2]

    puts ""
    puts ================================================================================$name
    puts ""

    set data [wget $url]

    set lastdate 0xffffffff

    set max 100000
    catch {
        set max $env(YAHOO_MAX)
    }

    foreach item [lrange [makelist $data <item>] 0 [expr $max - 1]] {
        if {[regexp {<link>([^<]+)</link>} $item dummy link] &&
            [regexp {<title>([^<]+)</title>} $item dummy title]} {
        } else {
            continue;
        }
        #puts $item

        regsub -all {&amp;} $title \\& title
        regsub -all {&quot;} $title \" title
        regsub -all {&#39;} $title {'} title

        if {![regexp {/([^/]+[.]html)$} $link dummy localname]} {
            continue
        }

        if {[info exists seen($link)]} {
            puts exist=$link
            continue
        }
        set seen($link) 1

        set fname [getcachefile $localname]
        set data [getfile $link $localname]
        set date [file mtime $fname]
        if {$date >= $lastdate} {
            set date [expr $lastdate - 1]
        }
        set lastdate $date

        set data [testing_get_file $data]

        if {[regexp {<div class="yom-mod yom-art-content *"[^>]*>(.*)<!-- END article -->} $data dummy data] ||
            [regexp {<div class="yom-mod yom-art-content *"[^>]*>(.*)<!-- google_ad_section_end -->} $data dummy data] ||
            [regexp {<div class=.body[^>]*>(.*)<!-- google_ad_section_end -->} $data dummy data] ||
            [regexp {<div class="yom-mod yom-art-content ">(.*)<div class="yom-mod yom-pagination yom-pagination2" id="mediapagination">} $data dummy data]} {
            regsub {<div class="yom-mod yom-follow".*} $data "" data
            regsub {<div class=.yfi-related-quotes.*} $data "" data
            regsub {<p class="first">By[^<]*</p>} $data "" data
            set data [sub_block $data <script> </script> ""]
            set data [sub_block $data <noscript> </noscript> ""]
            regsub {<!-- google_ad_section_end --></div></div>.*} $data <div data
            regsub {<div id="footer-promo">.*} $data "" data
            # puts $data
        } else {
            if {[regexp {(.*</item>)} $item "" item]} {
                regsub <title> $item "<title>@@" item
                regsub -all {<media[^>]*>} $item "" item
                regsub -all {</media[^>]*>} $item "" item
                append out "<item>$item"
            }
            puts "@@$title==$link"
            continue
        }

        regsub -all "\n<p><strong\[^>\]*>Related:</strong>\[^\n\]*</p>" $data "\n" data
        regsub -all {<p><strong\[^>\]*>Related:</strong>[^<]*<a href=[^>]*>[^<]+</a>} $data "" data

        puts $title==$link

        append out [makeitem $title $link $data $date]
    }
}
    append out {</channel></rss>}

    set fd [open ${datadir}_main.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}

set map {
    {
    main "Business & Finance News | Yahoo Finance" 
        http://finance.yahoo.com/news/;_ylt=AmEFggb5wb3RosqZH6iKkXKhuYdG;_ylu=X3oDMTI0ZzNjZmE2BG1pdANTdWJzY3JpYmUgYW5kIFNpdGUgSW5kZXggVG9wIFN0b3JpZXMEcG9zAzYEc2VjA01lZGlhUlNTRWRpdG9yaWFs;_ylg=X3oDMTFzdHZoMTdhBGludGwDdXMEbGFuZwNlbi11cwRwc3RhaWQDBHBzdGNhdANuZXdzfHByb3ZpZGVycwRwdANzZWN0aW9ucw--;_ylv=3?format=rss
    }
    {
    commodity "Commodities News and Information | Yahoo Finance"
        http://finance.yahoo.com/news/category-commodities/rss;_ylt=ApXoeBtSjABggoK1add9fmWhuYdG;_ylu=X3oDMTI0M29vYW91BG1pdANTdWJzY3JpYmUgYW5kIFNpdGUgSW5kZXggVVMgTWFya2V0cwRwb3MDMTgEc2VjA01lZGlhUlNTRWRpdG9yaWFs;_ylg=X3oDMTFzdHZoMTdhBGludGwDdXMEbGFuZwNlbi11cwRwc3RhaWQDBHBzdGNhdANuZXdzfHByb3ZpZGVycwRwdANzZWN0aW9ucw--;_ylv=3
    }
    {
    economy "Economy, Government & Policy News | Yahoo Finance"
        http://finance.yahoo.com/news/category-economy-govt-and-policy/rss;_ylt=ApsOxf3kAB7rj2QMqxWDwS.huYdG;_ylu=X3oDMTI1bHFtOWR2BG1pdANTdWJzY3JpYmUgYW5kIFNpdGUgSW5kZXggR2VuZXJhbCBOZXdzBHBvcwM2BHNlYwNNZWRpYVJTU0VkaXRvcmlhbA--;_ylg=X3oDMTFzdHZoMTdhBGludGwDdXMEbGFuZwNlbi11cwRwc3RhaWQDBHBzdGNhdANuZXdzfHByb3ZpZGVycwRwdANzZWN0aW9ucw--;_ylv=3
    }
    {
    international "International"
        http://finance.yahoo.com/news/category-economy/rss;_ylt=AuZRgW6lfCsYGR3_d_MoBhqhuYdG;_ylu=X3oDMTI2cnR0OGtvBG1pdANTdWJzY3JpYmUgYW5kIFNpdGUgSW5kZXggR2VuZXJhbCBOZXdzBHBvcwMxMgRzZWMDTWVkaWFSU1NFZGl0b3JpYWw-;_ylg=X3oDMTFzdHZoMTdhBGludGwDdXMEbGFuZwNlbi11cwRwc3RhaWQDBHBzdGNhdANuZXdzfHByb3ZpZGVycwRwdANzZWN0aW9ucw--;_ylv=3
    }
    {
    investing "Investing Ideas & Strategies | Yahoo Finance"
        http://finance.yahoo.com/news/category-ideas-and-strategies/rss;_ylt=AkPljMBDO2lA7YxU15jlwSyhuYdG;_ylu=X3oDMTI0dTRkanY1BG1pdANTdWJzY3JpYmUgYW5kIFNpdGUgSW5kZXggVVMgTWFya2V0cwRwb3MDMjcEc2VjA01lZGlhUlNTRWRpdG9yaWFs;_ylg=X3oDMTFzdHZoMTdhBGludGwDdXMEbGFuZwNlbi11cwRwc3RhaWQDBHBzdGNhdANuZXdzfHByb3ZpZGVycwRwdANzZWN0aW9ucw--;_ylv=3
    }
    {
    tech "Technology"
        http://finance.yahoo.com/news/sector-technology/rss;_ylt=Aqdb_Je_9Tx83qfarY3eOmmhuYdG;_ylu=X3oDMTIxbGJnMjFpBG1pdANTdWJzY3JpYmUgYW5kIFNpdGUgSW5kZXggU2VjdG9ycwRwb3MDMjEEc2VjA01lZGlhUlNTRWRpdG9yaWFs;_ylg=X3oDMTFzdHZoMTdhBGludGwDdXMEbGFuZwNlbi11cwRwc3RhaWQDBHBzdGNhdANuZXdzfHByb3ZpZGVycwRwdANzZWN0aW9ucw--;_ylv=3
    }
}

update
