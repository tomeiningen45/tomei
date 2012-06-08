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

# Tests
# http://localhost:8015/cgi-bin/channel.cgi?name=ANNnewsCH
# http://gdata.youtube.com/feeds/api/users/ANNnewsCH/uploads?orderby=updated&v=1&max-results=50
#
#
# CARandDRIVER, porsche

package require md5

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
    global fetch_err errorInfo isfake
    set data ""

    if {[catch {
        foreach num {50 25 10} {
            set url "http://gdata.youtube.com/feeds/api/users/$name/uploads?orderby=updated&v=1&max-results=50"
            set fd [open "|wget -q -O - $url 2> /dev/null"]
            fconfigure $fd -encoding utf-8
            set data [read $fd]
            set xmldata [convert $name $data]
            if {"$xmldata" != ""} {
                return 1
            }
        }
    } err]} {
        set fetch_err $err--\n$errorInfo
        if {[info exists isfake]} {
            puts stderr $fetch_err
        }
    }
    return 0
}

proc tagsplit {text tag} {
    regsub -all $tag $text \uffff text
    return [split $text \uffff]
}

proc open_info_cache {chan_name} {
    global env info_cache

    if {[info exists info_cache]} {
        return
    }

    set cache_file $env(DOCUMENT_ROOT)/ytunes_info.$chan_name.cache
    set cache_hash $env(DOCUMENT_ROOT)/ytunes_info.$chan_name.hash

    if {![file exists $cache_file] || ![file exists $cache_hash]} {
        return
    }

    set fd [open $cache_file]
    set data [read $fd]
    close $fd

    set fd [open $cache_hash]
    set oldmd5 [string trim [read $fd]]
    close $fd

    set md5 [::md5::md5 -hex $data]
    if {"$md5" != "$oldmd5"} {
        catch {file delete $cache_file}
        catch {file delete $cache_hash}
    }

    foreach line [split $data \n] {
        set watch [lindex $line 0]
        set info_cache(pubdate:$watch) [lindex $line 1]
        set info_cache(length:$watch)  [lindex $line 2]
        set info_cache(touch:$watch)   [lindex $line 3]
    }
}


proc save_info_cache {chan_name} {
    if {1} {
        return
    }
    global env info_cache isfake

    if {![info exists info_cache]} {
        return
    }

    set data ""

    foreach name [array names info_cache touch:*] {
        set watch [lindex [split $name :] 1]
        if {![info exists info_cache(fake:$watch)]} {
            append data "[list $watch $info_cache(pubdate:$watch) $info_cache(length:$watch) $info_cache(touch:$watch)]\n"
        }
    }

    set data [string trim $data]
    set md5 [::md5::md5 -hex $data]

    set cache_file $env(DOCUMENT_ROOT)/ytunes_info.$chan_name.cache
    set cache_hash $env(DOCUMENT_ROOT)/ytunes_info.$chan_name.hash

    set fd [open $cache_file w]
    puts -nonewline $fd $data
    close $fd

    set fd [open $cache_hash w]
    puts -nonewline $fd $md5
    close $fd
}

proc get_info {chan_name watch} {
    global env info_cache isfake last_pubdate

    open_info_cache $chan_name

    set info_cache(touch:$watch) $env(START_SEC)

    if {[info exists info_cache(pubdate:$watch)] &&
        [info exists info_cache(length:$watch)]} {
        return
    }

    set pubdate $env(START_SEC)
    set length  60
    set has_date 0
    set has_length 0

    if {[catch {
        set url "http://www.youtube.com/watch?v=$watch"
        set data [exec wget -q -O - $url 2> /dev/null]

        if {[regexp {<span id="eow-date"[^>]*>([^<]+)</span>} $data dummy date]} {
            catch {
                set pubdate [expr [clock scan $date] + 60 * 60 * 12]
                set has_date 1
            }
        }
        #NOT PUBLISH DATE -> regexp {"timestamp": ([0-9]+)} $data dummy pubdate
        if {[regexp {"length_seconds": ([0-9]+)} $data dummy length]} {
            set has_length 1
        }
    } err]} {
        #set fetch_err $err--\n$errorInfo
    }

    set info_cache(pubdate:$watch) $pubdate
    set info_cache(length:$watch)  $length

    if {!$has_date || !$has_length} {
        if {[info exists isfake]} {
            puts stderr "Using fake info: $watch [clock format $pubdate] $length"
        }
        set info_cache(fake:$watch) 1
    }
}

proc get_info_new {chan_name watch item} {
    global env info_cache isfake last_pubdate

    set pubdate [expr $last_pubdate - 1]
    set length 60
    regexp {<yt:duration seconds='([0-9]+)'/>} $item dummy length
    if {[regexp {<published>([^<]+)[.][^<]+Z</published>} $item dummy pubdatestr]} {
        #puts $pubdatestr
        catch {
            set pubdate [clock scan $pubdatestr -format {%Y-%m-%dT%H:%M:%S}]
            #puts [clock format $pubdate]
        }
    }

    set info_cache(pubdate:$watch) $pubdate
    set info_cache(length:$watch)  $length
    set last_pubdate $pubdate
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

            get_info_new $chan_name $watch $item

            if {[info exists isfake]} {
                puts "pubdate $watch [clock format $info_cache(pubdate:$watch)] == $info_cache(length:$watch)]"
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

            if {$total > 3 && false} {
                break
            }
        }
    }

    if {$total <= 0} {
        return "";
    }

    for {set i [expr $total - 2]} {$i >= 0} {incr i -1} {
        set this $wat([expr $i + 0])
        set next $wat([expr $i + 1])

        if {$info_cache(pubdate:$this) <= $info_cache(pubdate:$next)} {
            # Force iTunes to sort the list in same (time) order as in the feed
            # (or else same date means sort by title)
            set info_cache(pubdate:$this) [expr $info_cache(pubdate:$next) + 60]
            set dat($i) [clock format $info_cache(pubdate:$this)]
        }
    }

    puts "Content-Type: application/xhtml+xml"
    puts "Encoding: UTF-8"
    puts ""

    fconfigure stdout -encoding utf-8

    global feed_template

    regsub -all CHANNEL $feed_template $chan_name feed_template
    puts -nonewline $feed_template

    for {set i 0} {$i < $total} {incr i} {
        set t {
            <item>
            <title><![CDATA[TITLE]]></title>
            <link>LINK_URL</link>
            <author>Youtube</author>
            <description>DESCRIPTION</description>
            <itunes:author>Youtube</itunes:author>
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
    #save_info_cache $chan_name
    exit
}

proc hint {} {
    global env fetch_err

    puts "Content-Type: text/html"
    puts ""
    puts <ul>

    foreach {name title} {
        ANNnewsCH "ANN News Channel"
        CARandDRIVER "Car and Driver"
        autocar "AutoCar"
        evotv "EVO Magazine"
        TopGear TopGear
        NBA NBA
        Bloomberg Bloomberg
        NHKonline NHKonline
        adamcarollascarcast adamcarollascarcast
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
      <itunes:author>Youtube</itunes:author>
      <link>http://cnettv.cnet.com/</link>
      <copyright>CHANNEL</copyright>
      <description>Youtube: CHANNEL</description>
      <itunes:explicit>no</itunes:explicit>
      <itunes:summary>Youtube: CHANNEL</itunes:summary>
}

set last_pubdate [clock seconds]
main
#save_info_cache
exit 0
