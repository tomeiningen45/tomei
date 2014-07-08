#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/autotrader


set site(start) 2005
set site(end)   2011
set site(trans) MAN

if {[info exists env(AUTOTRADER_AUTO)]} {
    set site(desc)   "Autotrader Local 2009 - 2013 auto 911"
    set site(radius) 300
    set site(otherdir) /no.such/file
    set site(start) 2009
    set site(end)   2013
    set site(trans) AUT
    append datadir _auto
} elseif {[info exists env(AUTOTRADER_AUTO_REMOTE)]} {
    set site(desc)   "Autotrader Remote 2009 - 2013 auto 911"
    set site(radius)    0
    set site(otherdir)  ${datadir}_auto
    set site(start)     2009
    set site(end)       2013
    set site(trans) AUT
    append datadir      _auto_remote
} elseif {[info exists env(AUTOTRADER_REMOTE)]} {
    set site(desc)   "Autotrader Remote 2005 - 2011 manual 911"
    set site(radius) 0
    set site(otherdir) $datadir
    append datadir _remote
} else {
    set site(desc)   "Autotrader Local 2005 - 2011 manual 911"
    set site(otherdir) /no/such/file
    set site(radius) 300
}

catch {
    file mkdir $datadir
}

source $instdir/rss.tcl


set site(lang)     en
set site(encoding) utf-8
set site(step)     100
#set site(step)     50
set site(url)      http://www.autotrader.com/cars-for-sale/Porsche/911/Mountain+View+CA-94040?endYear=$site(end)&lastExec=1403591852000&listingTypes=all&makeCode1=POR&mmt=%5BPOR%5B911%5B%5D%5D%5B%5D%5D&modelCode1=911&numRecords=$site(step)&searchRadius=$site(radius)&startYear=$site(start)&transmissionCode=$site(trans)&Log=0

parray site

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------

set env(WGET_RETRY) {default}

set env(WGET_INIT_WAIT) {3000}
set env(WGET_RETRY) {4000 4000 2000 4000 8000 1000 1000 8000 8000 8000}

proc autotrader_get_articles {} {
    global site env

    set first 1
    set step  $site(step)
    set suffix ""
    set total 0

    set list ""
    set maxpages 100000
    catch {
        set maxpages $env(MAX_AUTOTRADER_PAGES)
    }
    puts $maxpages

    for {set p 0} {$p < $maxpages || $p == 0} {incr p} {
        set parsed 0
        set found 0
        set used 0
        set data [wget $site(url)$suffix]
        if {[regexp {<div class="no-results">} $data]} {
            break
        }

        foreach item [makelist $data listingId=] {
            incr parsed
            if {[regexp {^([0-9]+)} $item id]} {
                if {![info exists has($id)]} {
                    set has($id) 1
                    incr found
                    if {![file exists $site(otherdir)/$id]} {
                        #puts $id
                        lappend list $id
                        incr used
                        incr total
                    } else {
                        puts $id-other
                    }
                }
            }
        }
        incr first $step
        set suffix "&firstRecord=$first"
        puts "PARSED = $parsed, FOUND = $found, USED = $used, TOTAL = $total"
        if {$first > 1500} {
            # too many!
            break
        }
    }


    set result {}
    foreach id [lsort -integer -decreasing $list] {
        lappend result [list "http://www.autotrader.com/cars-for-sale/vehicledetails.xhtml?listingId=$id" $id \
                             "http://www.autotrader.com/cars-for-sale/vehicledetails/overview-tab.xhtml?listingId=$id"]
    }

    return $result
}


proc autotrader_parse_article {data} {
    set title notitle
    set hasimg 0

    if {[regexp {<title>AutoTrader.com</title>} $data]} {
        # page is not ready yet
        return [list *abort* "" "" 0]
    }

    if {[regexp {<title>([^<]+)</title>} $data dummy title]} {
        regsub "Cars for Sale: " $title "" title
        regsub "Porsche 911 " $title "" title
        regsub "Porsche " $title "" title
        regsub {, CA [0-9][0-9][0-9][0-9][0-9]:} $title {:} title
        regsub {, ([A-Z][A-Z]) [0-9][0-9][0-9][0-9][0-9]:} $title ", \\1:" title
        regsub {Details -.*} $title "" title
    }

    set carfax ""
    set hascf ""
    if {[regexp {<a href=\"(http://www.carfax.com/cfm/ccc_DisplayHistoryRpt.cfm[^\"]+)} $data dummy cf]} {
        set carfax "<p><a href=\"$cf\">CARFAX</a>"
        set hascf " CARFAX"
    }

    regsub {<span class="heading-trim">} $data "" data
    set list_title $title
    if {[regexp {<h1 class="listing-title atcui-block"[^>]*>([^<]+)} $data dummy x]} {
        set list_title $x
    }

    set mileage ""
    set price ""
    regexp {<span class="mileage">Mileage: ([^<]+)} $data dummy mileage

    regsub -all {<span title=[^>]+>} $data "" data
    regexp {<h4 class="primary-price"[^>]*>([^<]+)} $data dummy price

    if {$mileage != ""} {
        append price " @ $mileage mi"
    }

    if {[regexp -nocase {certified} $list_title]} {
        set title "Certified $title"
    }

    set content "$list_title - $price $carfax"

    set overview ""
    if {[regexp {<div class="overview-comments">.*} $data o]} {
        set overview <hr>$o<hr>
    }

    foreach item [makelist $data {"url":}] {
        if {[regexp {^\"(http[^\"]+jpg)\",\"thumbnail} $item dummy image]} {
            append content "\n<p><a href=$image><img src=$image></a>\n"
            incr hasimg 1
            append content $overview
            set overview ""
        }
    }
    append content $overview
    append title " ($hasimg) - [string trim $price$hascf]"

    set delete_if_old ""
    if {$hasimg < 1} {
        set delete_if_old 86400
    }

    return [list $title $content "&hasimg=$hasimg" $delete_if_old]
}


generic_news_site autotrader_get_articles autotrader_parse_article 10000 20
