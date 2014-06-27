#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/fortune
catch {
    file mkdir $datadir
}

source $instdir/rss.tcl

set site(lang)     en
set site(encoding) utf-8
set site(desc)     Fortune
set site(url)      http://money.cnn.com/magazines/fortune/


#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------

proc fortune_get_articles {} {
    global site
    set data [wget $site(url)]
    set list ""
    foreach item [makelist $data "href=\"http://"] {
        #puts $item
        if {[regexp "^(((tech)|(finance)|(management)).fortune.cnn.com/20../../../\[^>\]+/)\"" $item dummy link]} {
            if {![info exists seen($link)]} {
                set seen($link) 1
                lappend list [list "http://$link" [file tail $link]]
            }
        }
    }

    return $list
}



proc fortune_parse_article {data} {
    set title notitle

    if {![regexp {<h1>([^<]+)</h1>} $data dummy title]} {
        regexp {<title>([^<]+)</title>} $data dummy title
    }


    if {[regsub {.*<div id="storytext">} $data "" data] &&
        [regsub {<div class="taglist">Posted in:.*} $data "" data]} {

    } else {
        set data ""
        set title "@@$title"
    }

    return [list $title $data]
}


generic_news_site fortune_get_articles fortune_parse_article




