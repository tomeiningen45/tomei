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
        if {[regexp {This article will be updated to} $data]} {
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
        regsub -all {<span class="text">Videos you might like </span>} $data "" data

        #set data "<a href=$url>\[orig\] $title</a><p><p>$data"

        regsub {<h1>[^<]*</h1>} $data "" data
        regsub {<h5 class="headline".*} $data "" data
        regsub {<form class=.*} $data "" data

        # replace twitter embed blocks
        set twi_start {<blockquote class=.tweet-blockquote }
        while {[regexp $twi_start $data] && [regexp {<a href=\"(https://twitter.com/[^\"]+)} $data dummy link]} {
            set data [sub_block_single $data $twi_start {</blockquote>} "\n<p><BLOCKQUOTE><A href='$link'>Twitter</a></BLOCKQUOTE><p>\n"]
        }

        regsub -all {<div[^>]*>} $data "\n" data
        regsub -all {</div[^>]*>} $data "" data
        regsub -all {<a [^>]*>} $data "" data

        regsub -all {<button class="atom button" type="button">} $data "" data

        regsub -all {w_40,h_27,} $data {w_800,h_533,} data

	regsub "<ul><li style='DISPLAY:none'\[^\n\]*<span class=\"atom authorInfo\">" $data "" data
	regsub {<span class="text">[^<]+Watch more top videos, highlights, and B/R original content<!-- --> </span>} \
	    $data "" data

        save_article bleacher $title $url $data $pubdate
    }
}
