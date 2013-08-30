#----------------------------------------------------------------------
# Standard prolog (new gen)
#----------------------------------------------------------------------
source [file dirname [info script]]/rss.tcl


#-------------------------------------------------------------------------------
# To move into rss.lib
#-------------------------------------------------------------------------------
proc do_multi_sites {sites {argv {}}} {
    foreach s $sites {
        if {$argv != {} && [lsearch $s $argv] < 0} {
            continue
        }
        do_one_site $s
    }
}

proc do_one_site {siteinfo} {
    global datadir env

    set sitename   [lindex $siteinfo 0]
    set mainurl    [lindex $siteinfo 1]
    set index_proc [lindex $siteinfo 2]
    set body_proc  [lindex $siteinfo 3]

    set datadir data/$sitename
    catch {file mkdir $datadir}

    if {$index_proc == {}} {
        set index_proc ${sitename}_index_proc
    }
    if {$body_proc == {}} {
        set body_proc ${sitename}_body_proc
    }

    set lang en
    set date [clock format [clock seconds]]

    set out "<?xml version=\"1.0\" encoding=\"utf-8\"?> \n\
        <rss xmlns:dc=\"http://purl.org/dc/elements/1.1/\" \n\
             xmlns:sy=\"http://purl.org/rss/1.0/modules/syndication/\" \n\
             xmlns:admin=\"http://webns.net/mvcb/\" \n\
             xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" \n\
             xmlns:georss=\"http://www.georss.org/georss\" version=\"2.0\"> \n\
       <channel> \n\
         <title>$sitename</title> \n\
         <link>$mainurl</link> \n\
         <description>$sitename</description> \n\
         <dc:language>$lang</dc:language> \n\
         <pubDate>$date</pubDate> \n\
         <dc:date>$date</dc:date> \n\
         <sy:updatePeriod>hourly</sy:updatePeriod> \n\
         <sy:updateFrequency>1</sy:updateFrequency> \n\
         <sy:updateBase>2003-06-01T12:00+09:00</sy:updateBase>"

    set max 50
    catch {
        set max $env(MAX_${sitename})
    }

    set n 0
    set lastdate 0xffffffff

    foreach item [$index_proc $mainurl] {
        incr n
        if {$n > $max} {
            break
        }
        set url    [lindex $item 0]
        set title  [lindex $item 1]
        set fname  [lindex $item 2]

        if {"$fname" == ""} {
            set fname [getcachefile $url]
        }

        set data [getfile $url $fname]
        set date [file mtime $fname]
        if {$date >= $lastdate} {
            set date [expr $lastdate - 1]
        }
        set lastdate $date

        set data [$body_proc $data]

        puts $url=$title=$date
        append out [makeitem $title $url $data $date]
    }

    append out {</channel></rss>}

    set fd [open $datadir.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}

proc standard_index_proc {url match {pretrim {}} {posttrim {}}} {
    set data [wget $url]
    if {"$pretrim" != ""} {
        regsub $pretrim $data "" data
    }
    if {"$posttrim" != ""} {
        regsub $posttrim $data "" data
    }

    standard_index_proc_0 $data $match
}

proc standard_index_proc_0 {data match} {
    #puts $data
    set pat    [lindex $match 0]
    set urlidx [lindex $match 1]
    set titidx [lindex $match 2]

    set results {}
    #puts $pat
    while {[regexp $pat $data dummy a b c d e]} {
        #puts $a
        regsub $pat $data "" data
        set list [list $a $b $c $d $e]
        set url [lindex $list $urlidx]
        set tit [lindex $list $titidx]
        lappend results [list $url $tit]
    }

    return $results
}

proc filter_out {list script} {
    set results {}

    foreach item $list {
        set url   [lindex $item 0]
        set title [lindex $item 1]
        catch {eval $script} code
        if {!$code} {
            lappend results $item
        } else {
            #puts hello
        }
    }

    return $results
}

proc extract_and_junk_one_block {dataName begin end} {
    upvar $dataName data

    regsub -all $begin $data \uFFFE data
    regsub -all $end   $data \uFFFF data
    set pat {\uFFFE([^\uFFFF]*)\uFFFF}

    set result {}
    if {[regexp $pat $data dummy result]} {
        regsub $pat $data "" data
    }

    regsub -all \uFFFE $data $begin data
    regsub -all \uFFFF $data $end   data

    return $result
}

#----------------------------------------------------------------------
# Standard site-specific routines
#----------------------------------------------------------------------

proc pelican_index_proc {url} {
    return [filter_out \
                [standard_index_proc $url {
                    {<a href="([^"]+)" id="([^"]+)"[^>]*>([^<]+)</a>} 0 2
                }] {
                    if {[regexp forum-guidelines $url]} {
                        return 1
                    } else {
                        return 0
                    }
                }]
}

proc pelican_body_proc {data} {
    set result ""

    while 1 {
        set date [extract_and_junk_one_block data {<!-- status icon and date -->} {<!-- / status icon and date -->}]
        set body [extract_and_junk_one_block data {!-- message -->} {<!-- / message -->}]
        append results $date\n
        append results $body\n

        if {[string comp $date ""] == 0 &&
            [string comp $body ""] == 0} {
            break
        }
    }
    return $results
}

#----------------------------------------------------------------------
# Standard epilog (new gen)
#----------------------------------------------------------------------

do_multi_sites {
    {pelican    http://forums.pelicanparts.com/porsche-cars-sale/}
} $argv
