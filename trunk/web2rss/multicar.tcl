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
    foreach part [makelist [wget $url] {><a href=.webdetail.aspx[?]iid=}] {

        if {[regexp {^([0-9]+)} $part dummy link] &&
            [regexp {<img src="([^>]+.jpg)" +alt="([^>]+)" title=} $part dummy img title]} {
            set miles ""
            if {[regexp {([0-9,]+) Miles} $part dummy miles]} {
                set miles "$miles Miles"
            }

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
#--[ebay]-----------------------------------------------------------
proc ebay_index_proc {url} {
    set list ""
    foreach part [makelist [wget $url] {<table class="li nol"}] {
        if {[regexp {<tr><td class="cIt-cb">} $part]} {
            regsub {.*<tr itemscope="itemscope"[^>]*>} $part "" part
            regsub {</table>.*} $part " " part
            regsub -all {<a href=.javascript:[^>]*>} $part " " part

            if {[regexp "<a href=\"(http://cgi.ebay.com/ebaymotors/\[^\"\]+)" $part dummy link] &&
                [regexp "title=\"([quoted_exp]+)" $part dummy title]} {
                regsub {[?].*} $link "" link

                regsub -all {<tr[^>]*>} $part " " part
                regsub -all {<td[^>]*>} $part " " part
                regsub -all {</tr[^>]*>} $part " " part
                regsub -all {</td[^>]*>} $part " " part
                regsub -all {> *Watch this item *<} $part "><" part
                regsub -all "&quot;" $title \" title
                regsub -all "&amp;" $title \\& title
                regsub -all {<a href=[^>]+>[^<]+</a>} $part "" part
                regsub -all {>Listed:<} $part {>Listed: <} part

                set date ""
                if {[regexp {<span>([^>]+[0-9][0-9]:[0-9][0-9])</span>} $part dummy time]} {
                    catch {
                        set date [clock scan $time -format {%b-%d %H:%M}]
                    }
                }
                if {[regexp {<div>([0-9][0-9][0-9][0-9])</div>} $part dummy year]} {
                    if {$year > 1998} {
                        continue
                    }
                }
                if {[regexp {<div>([0-9]+),[0-9][0-9][0-9]</div>} $part dummy miles]} {
                    set year "$year ${miles}k"
                }
                if {[regexp {<div class="g-b">[$][0-9,.]+</div><div>([$][0-9,.]+)</div>} $part dummy price] ||
                    [regexp {([$][0-9,.]+) *<} $part dummy price]} {
                    regsub {[.]00$} $price "" price
                    set year "$year $price"
                }
                if {[regexp {Location: <span class="v">([^<]+)</span>} $part $dummy location]} {
                    set year "$year \[$location\]"
                }

                regsub -all {</a>} $part "" part
                regsub -all {<div[^>]*>} $part "" part
                regsub -all {</div[^>]*>} $part "<br>\n" part
                regsub -all {<img src="http://q.ebaystatic.com/aw/pics/s.gif"[^>]*><wbr/>} $part "" part
                regsub -all "<br>\n&nbsp;<br>\n<br>" $part "" part

                set fname ""
                set body "$part"
                set title "$year - [string trim $title]"

                lappend list [list $link $title $fname $body $date]
            }
        }
    }

    return $list
}

#----------------------------------------------------------------------
# Standard epilog (new gen)
#----------------------------------------------------------------------


#     

do_multi_sites {
    {ebay_911   http://motors.shop.ebay.com/Cars-Trucks-/6001/i.html?Model=911&Make=Porsche&&rt=nc&_dmpt=US_Cars_Trucks&_sticky=1&_sop=10&_sc=1&_ipg=100 ebay_index_proc}
    {ebay_930   http://motors.shop.ebay.com/Cars-Trucks-/6001/i.html?Model=930&Make=Porsche&&rt=nc&_dmpt=US_Cars_Trucks&_sticky=1&_sop=10&_sc=1&_ipg=100 ebay_index_proc}
    {mohr       http://www.mohrimports.com/view_inventory.php?make_id=16}
    {pelican    http://forums.pelicanparts.com/porsche-cars-sale/}
    {roadsport  http://roadsport.ebizautos.com/website.aspx?_used=true&_page=&_makef=porsche}
} $argv
