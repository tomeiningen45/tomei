#----------------------------------------------------------------------
# Standard prolog (new gen)
#----------------------------------------------------------------------
source [file dirname [info script]]/rss.tcl

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
