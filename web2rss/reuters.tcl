# @rss-nt-adapter@

namespace eval reuters {
    proc init {first} {
        variable h
        set h(filter_duplicates)  1
        set h(article_sort_byurl) 0
        set h(lang)  en
        set h(desc)  RT
        set h(url)   http://www.reuters.com
        set h(out)   rt
    }

    proc update_index {} {
        atom_update_index reuters http://feeds.reuters.com/reuters/topNews
    }

    proc parse_link {link} {
        set id ""
        regexp {([-]id[0-9A-Za-z]+)$} $link dummy id
        regsub {/[^/]+$} $link / link
        return ${link}${id}
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list reuters::parse_article [clock seconds]] $url
    }
    
    proc parse_article {pubdate url data} {
        set title "??"
        regexp {<title>([^<|]+)} $data dummy title
        
        regsub {.*(<div class=.ArticleBody_body)} $data "\\1" data
        regsub {.*(<div class=.ArticleHeader_content)} $data "\\1" data
        regsub {<div class=.ArticleBody_trust.*} $data "" data
        regsub {<div class=\"StandardArticleBody_trus.*} $data "" data

        regsub -all {<svg} $data "<!svg" data

        set pat {<div class=.LazyImage_image[^>]*url[\(]([^\)]+)[^>]*>}
        while {[regexp $pat $data dummy img]} {
            regsub {amp;w=[0-9]+} $img {amp;w=1024} img
            regsub -all "&quot;" $img "" img
            regsub -all "&amp;" $img  {\\\&} img
            regsub $pat $data "<img src=http:$img>" data
        }

        save_article reuters $title $url $data $pubdate
    }

    proc filter_duplicates {list} {
        set f {}
        foreach link [lreverse $list] {
            if {[regexp {([-]id[0-9A-Za-z]+)$} $link dummy id]} {
                #puts $id
                if {![info exists seen($id)]} {
                    set seen($id) 1
                    lappend f $link
                }
            }
        }
        return [lreverse $f]
    }
}
