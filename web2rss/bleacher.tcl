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
        if {![regexp {://bleacherreport.com/} $url]} {
            # avoid duplicated articles from other domains
            return
        }
        if {[regexp {This article will be updated to provide more information} $data]} {
            return
        }
        
        set title "??"
        regexp {<title>([^<|]+)} $data dummy title
 
        regsub {.*(<article )} $data "\\1" data
        regsub {(</article>).*} $data "\\1" data
        regsub {<footer.*} $data "" data
        regsub -all {<img[^>]+src="[^>]+team_logos/[^>]+"} $data "<noimg " data
        regsub -all {<img[^>]+src=[^>]+lazyImage/logo.png[^>]+>} $data "" data
        regsub -all {<span itemProp="citation"[^>]*>[^<]+</span>} $data "" data
        regsub -all {<span class="teamAvatar__name">[^<]+</span>} $data "" data



        set data [nosvg $data]
        regsub -all {<li (class=\"share)} $data {<li style='DISPLAY:none' \1} data
        regsub -all {<a (class="atom teamAvatar")} $data {<a style='DISPLAY:none'} data
        regsub {<h1 } $data {<h1 style='DISPLAY:none' } data
        regsub -all {w=80} $data {w=800} data
        regsub -all {h=53} $data {h=540} data
        regsub {<span class="name".*</header>} $data "" data
        regsub {<div class="organism video"} $data {<div style='DISPLAY:none'} data

        #set data "<a href=$url>\[orig\] $title</a><p><p>$data"

        regsub {<h1>[^<]*</h1>} $data "" data
        
        save_article bleacher $title $url $data $pubdate
    }
}
