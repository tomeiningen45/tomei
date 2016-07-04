set head {<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:media="http://search.yahoo.com/mrss/" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
    <title>MAIN_TITLE</title>
    <description>MAIN_DESC</description>
    <itunes:author>AUTHOR</itunes:author>
    <itunes:explicit>no</itunes:explicit>
}

set item {
    <item>
    <title>ITEM_TITLE</title>
    <description>ITEM_DESC</description>
    <pubDate>PUBDATE</pubDate>
    <guid isPermaLink="true">LINK</guid>
    <itunes:author>AUTHOR</itunes:author>
    <dc:creator>AUTHOR</dc:creator>
        
    <itunes:explicit>no</itunes:explicit>
    <itunes:duration>DURATION</itunes:duration>
    <itunes:summary>ITEM_DESC</itunes:summary>
    <enclosure url="LINK" type="audio/mpeg" length="DURATION" />
        
    </item>
}

set dirs {}
if {[llength $argv] >= 1} {
    set pwd [pwd]
    foreach dir $argv {
        cd $dir
        lappend dirs [pwd]
        cd $pwd
    }
}

set tail {
    </channel>
    </rss>
}

set oldpwd [pwd]
set root [file dirname [info script]]
cd $root
cd ..
set root [pwd]
cd $oldpwd

set datadir $root/tclhttpd3.5.1/htdocs/podcasts

proc replace {data pattern replacement} {
    regsub -all $pattern $data \uff00 data
    set out ""
    set prefix ""
    foreach part [split $data \uff00] {
        append out $prefix
        append out $part
        set prefix $replacement
    }
    return $out
}


proc mycomp {a b} {
    if {[regexp tin25000 $a]} {
        return [string comp $a $b]
    }
    set n [expr [file mtime $a] - [file mtime $b]]
    if {$n == 0} {
        return [string comp $a $b]
    } else {
        return $n
    }
}

if {"$dirs" == ""} {
    set dirs [glob $datadir/*]
}

foreach dir $dirs {
    catch {unset MAIN_TITLE}
    catch {unset MAIN_DESC}
    catch {unset AUTHOR}

    source $dir/config.tcl

    set out $head
    set out [replace $out MAIN_TITLE  $MAIN_TITLE]
    set out [replace $out MAIN_DESC   $MAIN_DESC]
    set out [replace $out AUTHOR      $AUTHOR]

    set outfile    $dir/podcast.xml
    set outfiletmp $outfile.tmp

    set ofd [open $outfiletmp w+]
    fconfigure $ofd -encoding utf-8
    puts $ofd $out

    cd $dir

    set n 0
    foreach mp3 [lsort -decreasing -command mycomp [glob *.mp3]] {
        set html [file root $mp3].html
        if {![file exists $mp3]} {
            continue
        }

        set title ""
        set comments ""
        set pubdate [file mtime $mp3]
        set date    [file mtime $mp3]

        set eyed3data ""
        set duration 00:00
        catch {
            set eyed3data [exec eyed3 --no-color $mp3 2> /dev/null]
            regexp {Time: ([0-9:]+)} $eyed3data dummy duration
            regsub -all "&" $eyed3data " and " eyed3data
        }

        if {[info exists $html]} {
            set fd [open $html]
            fconfigure $fd -encoding utf-8
            set data [read $fd]
            close $fd

            if {[regexp {<meta itemprop="datePublished" content="([^>]+)">} $data dummy d]} {
                catch {
                    set pubdate [clock scan $d]
                }
            }

            regexp {<title>([^<]+)</title>} $data dummy title
            regsub { - YouTube$} $title "" title
            regexp {name="description" content="([^<]+)">} $data dummy comments
        } else {
            regexp "title: (\[^\n\]+)" $eyed3data dummy title
            regsub "UserTextFrame:.*" $eyed3data "" eyed3data
            regexp "Comment: \[^\n\]+\n(\[^\n\]+)" $eyed3data dummy comments
            set comments [string trim $comments]

            if {[regexp tin25000 $mp3]} {
                regsub {^[56][a-z0-9][a-z0-9][a-z0-9][a-z0-9] } $title "" title
                regsub {^Bonchicast } $title "" title
                regsub {Bonchicast$} $title "" title

                catch {set pubdate [clock scan "20[string range $mp3 0 5]" -format %Y%m%d]}
            }
        }

        set pubdate [clock format $pubdate]
        set date [clock format $date -format %Y-%m-%d]

        set link http://localhost:9015/podcasts/[file tail $dir]/$mp3

        set out $item
        set out [replace $out ITEM_TITLE $title]
        set out [replace $out ITEM_DESC  $comments]
        set out [replace $out AUTHOR     $AUTHOR]
        set out [replace $out PUBDATE    $pubdate]
        set out [replace $out DURATION   $duration]
        set out [replace $out LINK       $link]

        puts "[format %3d $n] [file mtime $mp3] $title"
        puts $ofd $out
        incr n
    }
    puts $ofd $tail
    close $ofd
    file rename -force $outfiletmp $outfile
}


