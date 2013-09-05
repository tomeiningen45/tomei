#----------------------------------------------------------------------
# Standard prolog (new gen)
#----------------------------------------------------------------------
source [file dirname [info script]]/rss.tcl

#----------------------------------------------------------------------
# Standard site-specific routines
#----------------------------------------------------------------------


#--[pelican]-----------------------------------------------------------
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

#--[roadsport]-----------------------------------------------------------
proc roadsport_index_proc {url} {
    set list ""
    foreach part [makelist [wget $url] {<a href=.webdetail.aspx[?]iid=}] {

        if {[regexp {^([0-9]+)} $part dummy link] &&
            [regexp {<img src="([^>]+.jpg)" +alt="([^>]+)" title=} $part dummy img title]} {
            set miles ""
            regexp {([0-9,]+) Miles} $part dummy miles

            set link http://roadsport.ebizautos.com/webdetail.aspx?iid=$link
            set title "$title - $miles"
            set fname ""
            set body "$title<p><img src=$img><p>"

            lappend list [list $link $title $fname $body]
        }
    }
    return $list
}

#--[mohr]-----------------------------------------------------------
proc mohr_index_proc {url} {
    set list ""
    foreach part [makelist [wget $url] {<td width="160" valign="top">}] {
        if {[regexp {<img src="([^>]+.jpg)" class="img_border"} $part dummy img] &&
            [regexp {<strong>([^<]+)} $part dummy title] &&
            [regexp "<a href=\"(\[^>\"]+)\"" $part dummy link]} {
            set price "??"
            regexp {Floor Price<br />[^<]*<span class="yellow_txt">([^<]+)</span>} $part dummy price
            set price [string trim $price]
            
            set link http://www.mohrimports.com/$link
            set fname ""
            set body "$title<p>$price<p><img src=$img><p>"
            set title "$title - $price"

            lappend list [list $link $title $fname $body]
        }
    }
    return $list
}

#----------------------------------------------------------------------
# Standard epilog (new gen)
#----------------------------------------------------------------------


#     

do_multi_sites {
    {mohr       http://www.mohrimports.com/view_inventory.php?make_id=16}
    {pelican    http://forums.pelicanparts.com/porsche-cars-sale/}
    {roadsport  http://roadsport.ebizautos.com/website.aspx?_used=true&_page=&_makef=porsche}
} $argv
