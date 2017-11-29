# @rss-nt-adapter@

namespace eval reuters {
    proc init {first} {
        variable h
        set h(article_sort_byurl) 0
        set h(lang)  en
        set h(desc)  Reuters
        set h(url)   http://www.reuters.com
    }

    proc update_index {} {
        atom_update_index reuters http://feeds.reuters.com/reuters/topNews
    }

    proc parse_link {link} {
        regsub {/[^/]+$} $link / link
        return $link
    }
    
    proc parse_article {pubdate url data} {
        set title "??"
        regexp {<title>([^<|]+)} $data dummy title
        
        regsub {.*<div class=.ArticleBody_body} $data "<div" data
        regsub {<div class=.ArticleBody_trust.*} $data "" data
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
}
