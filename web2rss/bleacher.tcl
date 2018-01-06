# @rss-nt-adapter@

namespace eval bleacher {
    proc init {first} {
        variable h
        set h(filter_duplicates)  0
        set h(article_sort_byurl) 0
        set h(lang)  en
        set h(desc)  BR
        set h(url)   http://bleacherreport.com
        set h(out)   br
    }

    proc update_index {} {
        atom_update_index bleacher http://bleacherreport.com/articles/feed?tag_id=19
    }

    proc parse_link {link} {
        return $link
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list bleacher::parse_article [clock seconds]] $url
    }
    
    proc parse_article {pubdate url data} {
        set title "??"
        regexp {<title>([^<|]+)} $data dummy title
 
        regsub {.*(<article )} $data "\\1" data
        regsub {(</article>).*} $data "\\1" data
        regsub {<footer.*} $data "" data
        regsub {<img[^>]+src="[^>]+team_logos/[^>]+"} $data "<noimg " data
        
        set data [nosvg $data]
        regsub -all {<li (class=\"share)} $data {<li style='DISPLAY:none' \1} data
        regsub -all {<a (class="atom teamAvatar")} $data {<a style='DISPLAY:none'} data
        regsub {<h1 } $data {<h1 style='DISPLAY:none' } data
        regsub -all {w=80} $data {w=800} data
        regsub -all {h=53} $data {h=540} data
        save_article bleacher $title $url $data $pubdate
    }
}
