# @rss-nt-adapter@

namespace eval jalopnik {
    proc init {first} {
        variable h
        set h(filter_duplicates)  0
        set h(article_sort_byurl) 0
        set h(lang)  en
        set h(desc)  JALOPNIK
        set h(url)   http://jalopnik.com/
        set h(out)   jalopnik
    }

    proc update_index {} {
        atom_update_index jalopnik https://jalopnik.com/rss
    }

    proc parse_link {link} {
        return $link
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list jalopnik::parse_article [clock seconds]] $url
    }
    
    proc parse_article {pubdate url data} {
        set title "??"
        regexp {<title>([^<|]+)} $data dummy title
        regsub { - JALOPNIK} $title "" title

        if {[regsub {.*<div[^>]*js_post-content[^>]*>} $data "<div>" data] &&
            [regsub {<div[^>]*js_comments-iframe.*} $data "" data]} {
            set data [noscript $data]
            set data [sub_block $data {<svg[^>]*>} {</svg>} ""]
            set data [sub_block $data {<iframe } {</iframe>} ""]
            regsub -all {<div[^>]*((suggested)|(related)|(ad-mobile)|(video))[^>]*>} $data {<div style="display:none">} \
                data
            regsub -all {style="padding-bottom:[0-9.]+%"} $data "" data

            regsub -all {<picture class=} $data \uffff data
            regsub -all {</picture[^>]*>} $data \ufffe data

            while {[regsub {\uffff[^\ufffe]*data-srcset=\"([^\"]+)\"[^\ufffe]*\ufffe} $data {<img src="\1">} data]} {}


            regsub -all \uffff $data "<picture class=" data
            regsub -all \ufffe $data "</picture>" data


            # set data [redirect_images http://jalopnik.com/ $data]
            save_article jalopnik $title $url $data $pubdate
        }
    }
}
