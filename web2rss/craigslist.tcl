# @rss-nt-adapter@

namespace eval craigslist {
    proc init {first} {
        variable h
        set h(filter_duplicates)  0
        set h(article_sort_byurl) 0
        set h(lang)  jp
        set h(desc)  Craigslist
        set h(url)   https://sfbay.craigslist.org/d/cars-trucks/search/cta
        set h(out)   craigslist
    }

    proc update_index {} {
        schedule_index https://sfbay.craigslist.org/search/cta?query=F250+%7C+F150+%7C+Superduty+%7C+Ram+%7C+Silverado
    }

    proc schedule_index {index_url} {
        ::schedule_read [list craigslist::parse_index] $index_url
    }

    proc parse_index {index_url data} {
        set n 25
        foreach line [makelist $data {<h3 class="result-heading">}] {
            if {$n <= 0} {
                break
            }
            if {[regexp {<a href=.(https://sfbay.craigslist.org/[^>]*[.]html)} $line dummy article_url]} {
                #puts $n=[db_exists craigslist $article_url]=$article_url
                if {![db_exists craigslist $article_url] && ![info exists seen($article_url)]} {
                    ::schedule_read [list craigslist::parse_article [clock seconds]] $article_url
                    #return
                    set seen($article_url) 1
                    incr n -1
                }
            }
        }
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list craigslist::parse_article [clock seconds]] $url
    }
    
    proc parse_article {pubdate url data} {
        global g

        set title ""

        regsub {</span> - <span class="price">} $data " " data
        regsub {</span><small> \(} $data " @@ (" data

        if {![regexp {<span id="titletextonly">([^<]+)} $data dummy title] &&
            ![regexp {<title>([^<]+)} $data dummy title]} {
            return
        }

        set images "\n\n"
        set first_image ""
        if {[regexp {<div id="thumbs">.*} $data thumbs]} {
            regsub {</div>.*} $thumbs "" thumbs
            foreach line [makelist $thumbs href=.] {
                if {[regexp {^([^\"]+[.]jpg)} $line img]} {
                    if {"$first_image" == ""} {
                        set first_image "<img src='$g(webroot)/cgi-bin/im.cgi?a=[ncgi::encode $img]&b=[ncgi::encode $url]'>"
                    }                        
                    append images "\n<br><img src='$img'>"
                }
            }
        }
        set mileage ""
        if {[regexp {odometer: <b>([^<]+)</b>} $data dummy mileage]} {
            set mileage "@ ${mileage}mi"
            if {![regsub @@ $title "${mileage} " title]} {
                append title "$mileage"
            }
        }

        set attrs ""
        if {[regexp {<div class="mapAndAttrs">.*} $data attrs]} {
            regsub {<section id="postingbody">.*} $attrs "" attrs
            set attrs <blockquote>$attrs</blockquote>
        }

        if {[regsub {.*<section id="postingbody">} $data "" data]} {
            regsub {<ul class="notices">.*} $data "" data
            regsub {<p class="print-qrcode-label">QR Code Link to This Post</p>} $data "" data
            set data "$first_image$data"
            append data <!------>\n\n$attrs
            append data <!------>\\n\n$images
            save_article craigslist $title $url $data $pubdate
        }
    }
}

if 0 {

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

proc convert_title {title city {year_checker {}}} {
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
    # Remove other junk
    regsub -all {<[^>]+>} $title " " title
    regsub -all { +} $title { } title

    # remove "Stock XXXX"
    regsub -nocase {(^| )stock [A-Z0-9]+ } $title " " title
    set title [lowcap $title]

    # Type
    set type ""
    set pats {
        {930}
        {964}
        {Carrera 4S}
        {Carrera S}
        {Carrera 4}
        {Turbo Look}
        {Turbo S}
        {Turbo}
        {Convertible}
        {Cabriolet}
        {Cabrio}
        {Targa}
        {Coupe}
        {Carrera}
        {C2S}
        {C4S}
    }

    set prefix ""
    foreach pat $pats {
        if {[string first $pat $type] >= 0} {
            continue
        }
        if {[regexp -nocase "${pat} " "$title  "]} {
            append type $prefix$pat
            set prefix " "
        }
    }

    regsub {Convertible Cabrio} $type "Convertible" type
    regsub {Convertible Cabriolet} $type "Convertible" type
    regsub {Cabriolet} $type "Convertible" type
    regsub {Cabrio} $type "Convertible" type
    regsub {Convertible Carrera} $type "Convertible" type
    regsub {Targa Coupe} $type "Targa" type
    regsub {Targa Carrera} $type "Targa" type
    regsub {Coupe Carrera} $type "Coupe" type

    if {"$type" == ""} {
        set type ""
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

    if {$year_checker != ""} {
        if $year_checker {
            return ""
        }
    }

    set location [lowcap $location]
    if {"$location" != ""} {
        set location " $city: $location - "
    } else {
        set location " $city - "
    }
    set info "$year $type $price"
    regsub -all { +} $info { } info
    set info [string trim $info]

    set title "\[$info\] -${location} $title"
    regsub -all { +} $title { } title

    if {[regexp -nocase {(^| )((wanted)|(wtb))([^A-Za-z]|$)} $title]} {
        # skip wanted ads
        #puts XXX-$title
        return ""
    }

    return $title
}

proc mysort {a b} {
    set a [lindex $a 3]
    set b [lindex $b 3]

    if {$a == $b} {
        return 0
    } elseif {$a < $b} {
        return 1
    } else {
        return -1
    }
}

proc update {} {
    global datadir env

    set out  {<?xml version="1.0" encoding="utf-8"?>

<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">
  <channel>
    <title>Gregslist</title>
    <link>http://sfbay.craigslist.org</link>
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

    set max 500000
    catch {
        set max $env(CRAIG_MAX)
    }

    set max_cities 99999
    catch {
        set max_cities $env(CRAIG_MAX_CITIES)
    }

    if {[info exists env(CRAIG_LOCAL)]} {
        set sites {
            sfbay
            losangeles
            orangecounty
            monterey
            sacramento
            bakersfield
            chico
            fresno
            stockton
            ventura
            hanford
            humboldt
            medford
            mendocino
            merced
            modesto
            redding
            reno
            slo
            susanville
            sandiego
        }
        set extra _local
    } else {
        set sites {
            atlanta
            austin
            boston
            chicago
            dallas
            denver
            detroit
            houston
            lasvegas
            miami
            minneapolis
            newyork
            philadelphia
            phoenix
            portland
            raleigh
            seattle
            washingtondc
        }
        set extra ""
    }
    catch {
        set sites $env(CRAIG_SITES)
    }

    set allitems {}
    set nc 0
    set n 0
    foreach s $sites {
        puts -nonewline --[format %15s $s]--------------------------------------------------------------
        set data [wget "http://${s}.craigslist.org/search/cta?query=911%20|930%20|964%20|%20carrera&srchType=T"]
        set lastdate 0xffffffff

        set cars 0

        foreach line [makelist $data {<span class="date">}] {
            if {![regexp {<a href="([^>]+.html)">(.*)<span class="px">} $line dummy link title]} {
                continue
            }
            if {[regexp http:// $link]} {
                continue
            }

            set link http://${s}.craigslist.org$link

            set year_checker {"$year" == "" || ($year >= 1999 && $year <= 2004) || ($year > 2015)}

            set title [convert_title $title $s $year_checker]
            if {"$title" == ""} {
                continue
            }

            set fname [getcachefile $link.$s]

            set data [getfile $link $fname]
            set date [file mtime $fname]
            if {$date >= $lastdate} {
                set date [expr $lastdate - 1]
            }
            set lastdate $date

            if {![regexp -nocase porsche $data]} {
                # just another car with 911 or 930, etc, in the title
                continue
            }
            incr cars

            if {[regexp {<date title="([0-9]+)">201} $data dummy d]} {
                catch {
                    set date [expr $d / 1000]
                }
            }

            regsub {<section class="cltags".*} $data "" data
            regsub {.*<section class="userbody">} $data "" data
            regsub {<ul class="notices">.*} $data "" data
            regsub {<div class="postinginfos">.*} $data "" data

            regsub {<div class="mapAndAttrs">} $data "" data
            regsub {<div class="mapbox">} $data "" data
            regsub {<div id="map" [^>]*>} $data "" data
            regsub {<p class="mapaddress">} $data "" data
            regsub {.<a target="_blank" [^>]*>google map</a>.} $data "" data
            regsub {.<a target="_blank" [^>]*>yahoo map</a>.}  $data "" data
            regsub {<div class="mapaddress">[^<]*</div>}  $data "" data

            #puts ==$data==

            set pat {<figure class="iw">.*</figure>}
            if {[regexp $pat $data images]} {
                regsub $pat $data "" data

                set first 1
                foreach item [makelist $images {<a href=}] {
                    if {[regexp {^"([^<]+[.]jpg)"} $item dummy img]} {
                        #puts $img
                        set img "<a href=$img><img src=$img></a>"
                        if {$first} {
                            set data "$img<p><hr>\n$data\n<hr>\n"
                            set first 0
                        } else {
                            set data "$data<p>\n$img"
                        }
                    }
                }
            }
            set data [sub_block $data {<script[^>]*>} </script> ""]

            catch {
                set data [clock format $date]<br>$data
            }

            #append out [makeitem $title $link $data $date]
            lappend allitems [list $title $link $data $date]

            #puts "$link [clock format $date -format %D] $title"

            incr n
            if {$n >= $max} {
                set nc 1000000
                break
            }
        }
        puts " \[$cars\]"
        incr nc
        if {$nc >= $max_cities} {
            break
        }
    }

    foreach item [lsort -command mysort $allitems] {
        set title [lindex $item 0]
        set link  [lindex $item 1]
        set data  [lindex $item 2]
        set date  [lindex $item 3]

        puts [clock format $date -format %D]=$title=

        append out [makeitem $title $link $data $date]
    }


    append out {</channel></rss>}

    set fd [open $datadir$extra.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}


update
}
