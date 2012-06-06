#!/bin/sh
# \
if [ -e /usr/bin/tclsh ]; then exec /usr/bin/tclsh "$0" ${1+"$@"} ; fi
# \
if [ -e /usr/local/bin/tclsh8.4 ]; then exec /usr/local/bin/tclsh8.4 "$0" ${1+"$@"} ; fi
# \
if [ -e /usr/local/bin/tclsh8.3 ]; then exec /usr/local/bin/tclsh8.3 "$0" ${1+"$@"} ; fi
# \
if [ -e /usr/bin/tclsh8.4 ]; then exec /usr/bin/tclsh8.4 "$0" ${1+"$@"} ; fi
# \
exec tclsh "$0" ${1+"$@"}


#----------------------------------------------------------------------
# This is for testing in the command-line
#
if {![info exists env(QUERY_STRING)]} {
    set env(QUERY_STRING) [lindex $argv 0]
}
if {![info exists env(SCRIPT_NAME)]} {
    set env(SCRIPT_NAME) [info script]
}
if {![info exists env(HTTP_HOST)]} {
    set env(HTTP_HOST) localhost:8015
}
if {![info exists env(DOCUMENT_ROOT)]} {
    set env(DOCUMENT_ROOT) [exec sh -c "cd [file dirname [info script]]; cd ..; pwd"]
    set isfake 1
}
#----------------------------------------------------------------------test

set env(START_SEC) [clock seconds]

proc main {} {
    global env

    if {"$env(QUERY_STRING)" != ""} {
        if {[regexp {^name=(.*)} $env(QUERY_STRING) dummy name]} {
            if {[print_rss $name]} {
                exit 0
            }
        }
    }

    hint
}

proc print_rss {name} {
    global fetch_err errorInfo

    set data ""

    if {[catch {
        foreach num {50 25 10} {
            set url "http://gdata.youtube.com/feeds/api/users/$name/uploads?orderby=updated&v=1&max-results=50"
            set data [exec wget -q -O - $url 2> /dev/null]
            set xmldata [convert $name $data]
            if {"$xmldata" != ""} {

                return 1
            }
        }
    } err]} {
        set fetch_err $err--\n$errorInfo
    }
    return 0
}

proc tagsplit {text tag} {
    regsub -all $tag $text \uffff text
    return [split $text \uffff]
}

proc open_info_cache {} {
    global env info_cache

    if {[info exists info_cache]} {
        return
    }

    set cache_file $env(DOCUMENT_ROOT)/ytunes_info.cache
    set cache_hash $env(DOCUMENT_ROOT)/ytunes_info.hash

    if {![file exists $cache_file]} {
        return
    }
}

proc get_info {watch} {
    global env info_cache isfake

    set info_cache(touch:$watch) $env(START_SEC)

    if {[info exists info_cache(pubdate:$watch)] &&
        [info exists info_cache(length:$watch)]} {
        return
    }

    set pubdate $env(START_SEC)
    set length  60

    if {[catch {
        set url "http://www.youtube.com/watch?v=$watch"
        set data [exec wget -q -O - $url 2> /dev/null]

        if {[regexp {<span id="eow-date"[^>]*>([^<]+)</span>} $data dummy date]} {
            catch {
                set pubdate [clock scan $date]
            }
        }
        regexp {"length_seconds": ([0-9]+)} $data dummy length

    } err]} {
        #set fetch_err $err--\n$errorInfo
    }

    set info_cache(pubdate:$watch) $pubdate
    set info_cache(length:$watch)  $length
}

proc convert {chan_name data} {
    global env info_cache isfake
    set root http://$env(HTTP_HOST)

    set total 0
    foreach item [tagsplit $data {<title[^>]*>}] {
        incr idx
        if {$idx <= 2} {
            continue
        }
        regsub -all "&" $item "\\\\&" item
        if {[regexp {^([^<]+)</title>} $item dummy title]} {
            set description ""
            set video ""
            if {![regexp {<media:description[^>]*>([^<]+)</media:description>} $item dummy description] ||
                ![regexp {<link[^>]*href='http://www.youtube.com/watch[?]v=([A-Za-z0-9_+-]+)} $item dummy watch]} {
                continue
            }

            get_info $watch
            if {[info exists isfake]} {
                puts "pubdate $watch [clock format $info_cache(pubdate:$watch)]"
            }

            set i $total; incr total

            set wat($i) $watch
            set tit($i) [string trim $title]
            set des($i) [string trim $description]
            set url($i) $root/cgi-bin/movie.mp4?name=$watch

            set sum($i) $des($i)
            if {[string first "<!\[CDATA\[" $sum($i)] != 0} {
                set sum($i) "<!\[CDATA\[$sum($i)\]\]"
            }
            #set dat($i) "Wed, 30 May 2012 03:01:36 PDT"
            set dat($i) [clock format $info_cache(pubdate:$watch)]
            set dur($i) $info_cache(length:$watch)

            if {$total > 10 && false} {
                break
            }
        }
    }

    if {$total <= 0} {
        return "";
    }

    puts "Content-Type: application/xhtml+xml"
    puts "Encoding: UTF-8"
    puts ""

    global feed_template

    regsub -all CHANNEL $feed_template $chan_name feed_template
    puts -nonewline $feed_template

    for {set i 0} {$i < $total} {incr i} {
        set t {
            <item>
            <title><![CDATA[TITLE]]></title>
            <link>LINK_URL</link>
            <author>AUTHOR</author>
            <description>DESCRIPTION</description>
            <itunes:author>AUTHOR</itunes:author>
            <itunes:duration>DURATION</itunes:duration>
            <enclosure url="MEDIA_URL" length="0" type="video/mp4" />
            <pubDate>DATE</pubDate>
            <media:content url="MEDIA_URL" type="video/mp4" /></item>
        }

        regsub -all TITLE       $t $tit($i)    t
        regsub -all LINK_URL    $t "http://www.youtube.com/watch?v=$wat($i)" t
        regsub -all MEDIA_URL   $t $url($i)    t
        regsub -all DESCRIPTION $t $des($i)    t
        regsub -all GUID        $t $i          t
        regsub -all DATE        $t $dat($i)    t
        regsub -all AUTHOR      $t $chan_name  t
        regsub -all DURATION    $t $dur($i)    t

        puts $t
    }

    puts "</channel></rss>"
    exit
}

proc hint {} {
    global env fetch_err

    puts "Content-Type: text/html"
    puts ""
    puts <ul>

    foreach {name title} {
        CARandDRIVER "Car and Driver"
    } {
        puts "<li><a href=$env(SCRIPT_NAME)?name=$name>$title</li>"
    }
    puts "</ul>"
    if {[info exists fetch_err]} {
        puts "<pre>ERROR:\n$fetch_err</pre>"
    }
}

set feed_template {<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" media="screen" href="/~d/styles/rss2enclosuresfull.xsl"?>
<?xml-stylesheet type="text/css" media="screen" href="http://feeds.feedburner.com/~d/styles/itemcontent.css"?>
<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/" xmlns:feedburner="http://rssnamespace.org/feedburner/ext/1.0" version="2.0">
    
  <channel>
      
      <title>Youtube: CHANNEL</title>
      <itunes:author>CHANNEL</itunes:author>
      <link>http://cnettv.cnet.com/</link>
      <copyright>CHANNEL</copyright>
      <description>Youtube: CHANNEL</description>
      <itunes:explicit>no</itunes:explicit>
      <itunes:summary>Youtube: CHANNEL</itunes:summary>
}

main
exit 0
