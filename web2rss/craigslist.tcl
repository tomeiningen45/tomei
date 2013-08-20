#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/craigslist
catch {
    file mkdir $datadir
}

source $instdir/rss.tcl

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------

proc lowcap {line} {
    set prefix ""
    set val ""
    foreach word [split $line " "] {
        if {[regexp {^([A-Z])([A-Za-z].*)$} $word dummy first rest]} {
            set word ${first}[string tolower $rest]
        }
        append val ${prefix}${word}
        set prefix " "
    }
    return $val
}

proc update {} {
    global datadir env

    set out  {<?xml version="1.0" encoding="utf-8"?>

<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">
  <channel>
    <title>Gregslist</title>
    <link>http://sfbay.craigslist.org/link>
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
    regsub -all LANG        $out en    out
    regsub -all DESC        $out crg   out

    set newlinks {}

    set max 50
    if {[info exists env(CRAIG_MAX)]} {
        set max $env(CRAIG_MAX)
    }

    set n 0
    set data [wget {http://sfbay.craigslist.org/search/cta?query=911%20|930%20|964%20|%20carrera&srchType=T}]
    set lastdate 0xffffffff

    foreach line [makelist $data {<span class="date">}] {
        if {![regexp {<a href="([^>]+.html)">(.*)<span class="px">} $line dummy link title]} {
            continue
        }

        # Price
        set price ""
        set pat {<span class="price">([^<]+)</span>}
        if {[regexp $pat $title dummy price]} {
            regsub $pat $title " " title
        }

        # Location
        set location ""
        set pat {<span class="pnr"> <small>([^<]+)</small>}
        if {[regexp $pat $title dummy location]} {
            regsub \\( $location "" location
            regsub \\) $location "" location
            set location [string trim $location]
            regsub $pat $title " " title
        }

        regsub -all { +} $title { } title

        # Type
        set type ""
        set pats {
            {Carrera S}
            {Carrera 4}
            {Carrera 4S}
            {Turbo}
            {Convertible}
            {Cabriolet}
            {Targa}
        }

        set prefix ""
        foreach pat $pats {
            if {[regexp -nocase $pat $title]} {
                append type $prefix$pat
                set prefix " "
            }
        }

        regsub {Convertible Cabriolet} $type "Convertible" type
        regsub {Cabriolet} $type "Convertible" type
        if {"$type" == ""} {
            set type Carrera
        }

        # Year
        set year ""
        set pats {
            (20[0-9][0-9])
            (19[0-9][0-9])
            ([6-9][0-9])
            ([0-1][0-9])
        }
        foreach pat $pats {
            set pat "(^| |'|`|>)${pat}(\$|\[^0-9\])"
            if {[regexp $pat $title dummy dummy year]} {
                if {[string length $year] == 2} {
                    if {[regexp {^[01]} $year]} {
                        set year 20$year
                    } else {
                        set year 19$year
                    }
                }
                break
            }
        }

        # Remove other junk
        regsub -all {<[^>]+>} $title " " title
        regsub -all { +} $title { } title

        set title [lowcap $title]
        set location [lowcap $location]
        if {"$location" != ""} {
            set location " $location - "
        }
        set info "$year $type $price"
        regsub -all { +} $info { } info
        set info [string trim $info]


        set title "\[$info\] -${location}$title"


        set link http://sfbay.craigslist.org$link

        puts "$link=$title"

        set fname [getcachefile $link]

        set data [getfile $link [file tail $link]]
        set date [file mtime $fname]
        if {$date >= $lastdate} {
            set date [expr $lastdate - 1]
        }
        set lastdate $date


        regsub {<section class="cltags".*} $data "" data
        regsub {.*<section class="userbody">} $data "" data

        #puts ==$data==

        set pat {<figure class="iw">.*</figure>}
        if {[regexp $pat $data images]} {
            regsub $pat $data "" data

            set first 1
            foreach item [makelist $images {<a href=}] {
                if {[regexp {^"([^<]+[.]jpg)"} $item dummy img]} {
                    #puts $img
                    set img "<img src=$img>"
                    if {$first} {
                        set data "$img<p><hr>$data<hr>"
                        set first 0
                    } else {
                        set data "$data<p>$img"
                    }
                }
            }
        }

        append out [makeitem $title $link $data $date]

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