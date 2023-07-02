# @rss-nt-adapter@

namespace eval basketballking {
    proc init {first} {
        variable h
        set h(article_sort_byurl) 0
        set h(lang)  en
        set h(desc)  {BASKETBALLKING}
        set h(url)   https://basketballking.jp/news/category/world?cx_top=head
        set h(out)   basketballking
    }

    proc update_index {} {
	::schedule_read [list basketballking::parse_index] https://basketballking.jp/news/category/world?cx_top=head
    }

    proc parse_index {index_url data} {
	global
	set list {}
	puts [string length $data]

        foreach line [makelist $data { href=\"}] {
            if {[regexp {^([^"]+cx_cat=page1)"} $line dummy link]} {
		puts $link
		lappend list $link
	    }
	}
        foreach article_url $list {
            if {![db_exists basketballking $article_url]} {
                ::schedule_read basketballking::parse_article $article_url utf-8
            }
        }
    }


    proc debug_article_parser {url} {
        ::schedule_read basketballking::parse_article $url utf-8
    }

    proc parse_article {url data} {
	set title "$url"
	regexp {<title>([^<]+)</title>} $data dummy title
	regsub { | バスケットボールキング} $title "" title
	set pubdate [clock seconds]

	regsub {.*<div class="contents-main">} $data "" data
	regsub {<!-- ここまで wp_content -->.*} $data "" data
	regsub {<div class="next-page">.*} $data "" data
    	regsub {<div class="social-button">.*} $data "" data

	regsub {<div class="mainVisual-alt">} $data "<br>" data
	
	regsub {<h1>[^<]*</h1>} $data "" data
    	regsub -all {<div[^>]*>} $data "" data
    	regsub -all {</div[^>]*>} $data "" data

	regsub {<a href="https://basketballking.jp/news/category/[^>]*">[^<]*</a>} $data "" data
	regsub {<a href="[^<]*">バスケットボールキング編集部</a>} $data "" data
	regsub {<a href="[^<]*">[^<]*<img width="150" height="150" [^>]*>[^<]*</a>} $data "" data
	regsub {202[0-9].[0-9][0-9].[0-9][0-9][^<]*<[^>]*article_UnderTitle -->} $data "" data
	regsub {[0-9]+時間前[^<]*<[^>]*article_UnderTitle -->} $data "" data
	set data [noscript $data]

	regsub -all {.写真.[=＝][^<]*} $data "" data
	
	#set data [redirect_images https://www.basketballking.com/ $data]
	
        save_article basketballking $title $url $data $pubdate
    }
}
