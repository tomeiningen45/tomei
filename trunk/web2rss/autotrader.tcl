#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/autotrader

if {[info exists env(AUTOTRADER_REMOTE)]} {
    set site(radius) 0
    set site(otherdir) $datadir
    append datadir _remote
} else {
    set site(otherdir) /no/such/file
    set site(radius) 300
}

catch {
    file mkdir $datadir
}

source $instdir/rss.tcl


set site(lang)     en
set site(encoding) utf-8
set site(desc)     Autotrader
set site(step)     100
#set site(step)     50
set site(url)      http://www.autotrader.com/cars-for-sale/Porsche/911/Mountain+View+CA-94040?endYear=2011&lastExec=1403591852000&listingTypes=all&makeCode1=POR&mmt=%5BPOR%5B911%5B%5D%5D%5B%5D%5D&modelCode1=911&numRecords=$site(step)&searchRadius=$site(radius)&startYear=2005&transmissionCode=MAN&transmissionCodes=MAN&Log=0

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------

proc autotrader_get_articles {} {
    global site

    set first 1
    set step  $site(step)
    set suffix ""

    set list ""
    while 1 {
        set data [wget $site(url)$suffix]
        if {[regexp {<div class="no-results">} $data]} {
            break
        }

        foreach item [makelist $data listingId=] {
            if {[regexp {^([0-9]+)} $item id]} {
                if {![info exists found($id)]} {
                    set found($id) 1
                    if {![file exists $site(otherdir)/$id]} {
                        puts $id
                        lappend list [list "http://www.autotrader.com/cars-for-sale/vehicledetails.xhtml?listingId=$id" $id]
                    } else {
                        puts $id-other
                    }
                }
            }
        }
        incr first $step
        set suffix "&firstRecord=$first"
    }

    return $list
}



proc autotrader_parse_article {data} {
    set title notitle

    if {[regexp {<title>([^<]+)</title>} $data dummy title]} {
        regsub "Cars for Sale: " $title "" title
        regsub {, CA [0-9][0-9][0-9][0-9][0-9]:} $title {:} title
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

    append title " - $price$hascf"
    set content "$list_title - $price $carfax"

    foreach item [makelist $data {"url":}] {
        if {[regexp {^\"(http[^\"]+jpg)\",\"thumbnail} $item dummy image]} {
            append content "\n<p><a href=$image><img src=$image></a>\n"
        }
    }

    return [list $title $content]
}


generic_news_site autotrader_get_articles autotrader_parse_article 10000
