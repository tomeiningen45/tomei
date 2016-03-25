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
    <enclosure url="LINK" type="audio/mpeg" length="DURATION" />
        
    </item>
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
    set n [expr [file mtime $a] - [file mtime $b]]
    if {$n == 0} {
        return [string comp $a $b]
    } else {
        return $n
    }
}

foreach dir [glob $datadir/*] {
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

        set fd [open $html]
        fconfigure $fd -encoding utf-8
        set data [read $fd]
        close $fd

        set title ""
        set comments ""
        set pubdate [file mtime $mp3]
        set date    [file mtime $mp3]
        if {[regexp {<meta itemprop="datePublished" content="([^>]+)">} $data dummy d]} {
            catch {
                set date [clock scan $d]
            }
        }
        set pubdate [clock format $pubdate]
        set date [clock format $date -format %Y-%m-%d]

        regexp {<title>([^<]+)</title>} $data dummy title
        regsub { - YouTube$} $title "" title
        regexp {name="description" content="([^<]+)">} $data dummy comments

        set duration 00:00
        catch {
            set data [exec eyed3 --no-color $mp3 2> /dev/null]
            regexp {Time: ([0-9:]+)} $data dummy duration
        }

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


