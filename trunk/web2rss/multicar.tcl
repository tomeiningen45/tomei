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
    return [process_indices \
                [standard_index_proc $url {
                    "<a class=\"wideLargeVehicleDescription\" href=\"(\[^\"]+)\"\[^>\]*>(\[^<\]+)</a>" 0 1
                }] {
                    set url http://roadsport.ebizautos.com/$url
                }]
}

#----------------------------------------------------------------------
# Standard epilog (new gen)
#----------------------------------------------------------------------


#     {roadsport  http://roadsport.ebizautos.com/website.aspx?_used=true&_page=&_makef=porsche}

do_multi_sites {
    {pelican    http://forums.pelicanparts.com/porsche-cars-sale/}
} $argv
