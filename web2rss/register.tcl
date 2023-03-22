# @rss-nt-adapter@

namespace eval register {
    proc init {first} {
        variable h
        set h(filter_duplicates)  0
        set h(article_sort_byurl) 0
        set h(lang)  en
        set h(desc)  TheRegister
        set h(url)   http://www.theregister.co.uk/
        set h(out)   register
    }

    proc update_index {} {
        atom_update_index register http://www.theregister.co.uk/headlines.atom
    }

    proc parse_link {link} {
	puts stderr $link
        return $link
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list register::parse_article [clock seconds]] $url
    }
    
    proc parse_article {pubdate url data} {
	set title "??"
	regsub {...The Register</title>} $data {</title>} data
        regexp {<title>([^<|]+)} $data dummy title

        regsub {.*<div id="article">} $data "" data
        regsub {.*<div id="body">} $data "" data
        regsub {<div class="wptl btm">.*} $data "" data

        save_article register $title $url $data $pubdate
    }
}


if 0 {

#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/register
catch {
    file mkdir $datadir
}

source $instdir/rss.tcl

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------

proc update {} {
    global datadir env

    set out  {<?xml version="1.0" encoding="utf-8"?>

<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">  
  <channel> 
    <title>register</title>  
    <link>http://register.com</link>  
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

    set newlinks {}

    set max 600
    if {[info exists env(REGISTER_MAX)]} {
        set max $env(REGISTER_MAX)
    }

    set n 0
    foreach {title link description pubdate} [extract_feed http://www.theregister.co.uk/headlines.atom] {
        #puts $title\n\t$link\n\t$pubdate\n\t$description\n
        #continue

        if {![regexp {/([^/]+)/$} $link dummy localname]} {
            continue
        }

        puts -nonewline $link
        flush stdout
        set started [now]

        set fname [getcachefile $localname]
        set data [getfile $link $localname utf-8]
        puts "  [expr [now] - $started] secs"

        if {[regexp {<div id="body">(.*)((<div id=in_article_forums>)|(<div id=article_body_btm>)|(<div class="post reply edited">))} $data dummy data] ||
            [regexp {<section id="body">(.*)<section class="comments">} $data dummy data]} {
            regsub {<div id=in_article_forums>.*} $data "" data
            regsub {<div class="post reply edited">.*} $data "" data
            regsub -all {<p class="wptl[^>]*"><a href="[^>]*">[^<]*</a></p>} $data "" data
            regsub {<p><strong class="trailer">([^<]+)</strong>} $data {【\1】 } data

            set data [sub_block $data {<script[^>]*>} </script> ""]
            set data [sub_block $data <noscript> </noscript> ""]

            set description $data
        } else {
            puts "-- failed to parse contents"
            set title "@@$title"
        }

        #puts $data
        #exit
        append out [makeitem $title $link $description $pubdate]
        catch {
            lappend newlinks [clock scan $pubdate] $link
        }

        incr n
        if {$n >= $max} {
            break
        }
    }

    append out {</channel></rss>}

    set fd [open $datadir.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}

update

}
