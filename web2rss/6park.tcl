# @rss-nt-adapter@

namespace eval 6park {
    proc init {first} {
        variable h
        set h(article_sort_byurl) 0
        set h(lang)  zh
        set h(desc)  留园
        set h(url)   http://www.6park.com
    }

    proc update_index {} {
        ::schedule_read 6park::parse_index https://www.6parknews.com/newspark/index.php utf-8
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {article_url} {
        ::schedule_read 6park::parse_article $article_url
    }

    proc parse_index {index_url data} {
        set list {}

        foreach line [makelist $data {"nid":}] {
            if {[regexp {^"([^\"]+)"} $line dummy id] &&
                [regexp {"title":"([^\"]+)"} $line dummy title] &&
                [regexp {"url":"([^\"]+)"} $line dummy url]} {

                regsub ☆ $title "" title
                set url "https://www.6parknews.com/newspark/$url"

                if {![info exists seen($url)]} {
                    set seen($url) 1
                    lappend list [list $url $title $id]
                }
            }
        }

        foreach item [lsort -dictionary $list] {
            # Get the oldest article first
            set article_url [lindex $item 0]
            set title       [lindex $item 1]
            set id          [lindex $item 2]
            if {![db_exists 6park $article_url]} {
                ::schedule_read [list 6park::parse_toutiaoabc $id $title] $article_url utf-8
                incr n
                if {$n > 10} {
                    # dont access the web site too heavily
                    break
                }
            }
        }
    }

    proc parse_toutiaoabc {id title url data} {
        set from ""
        regexp {新闻来源: ([^ ]+)} $data dymmy from

        regsub {.*<div id="mainContent">} $data "" data
        regsub {.*<div id='shownewsc' style="margin:15px;">} $data "" data
        regsub {.*<div class="article-content" id="article-content">} $data "" data
        regsub {.*<!-- 文章内容 -->} $data "" data

        regsub {<table class='xianhua_jidan'.*} $data "" data
        regsub {<span class='ad_title'>Advertisements</span></div>.*} $data "" data
        regsub {<!-- 文章内容结束 -->.*} $data "" data
        regsub {<a href=[^>]+target=_blank><img[^>]+转发本条新闻到微博'></a>} $data "" data

        set data [sub_block $data "<script" "</script>" ""]
        set data [sub_block $data {<ins class="adsbygoogle"} "</ins>" ""]
        
        if {"$from" != ""} {
            set data "【$from】 $data"
        }

        # most of the center tags are wrong on 6park
        regsub -all <center> $data <!--noceneter--> data
        regsub -all </center> $data "" data
        regsub -all {align='center'} $data "" data

        # fix images
        regsub -all {onload='javascript:if[(]this.width>600[)] this.width=600'} $data "" data
        regsub -all {<br [^>]*>} $data <br> data
        regsub -all {<br>.[ 　]+} $data "<br>" data
        regsub -all {<br>.<b>[ 　]+} $data "<br><b>" data
        regsub -all "\n\[ \t\r\]+<" $data "\n<" data
        regsub -all "<br>(\n<br>)+" $data "<br><br>\n" data
        regsub -all {>[ 　]+<} $data "><" data

        # don't show 6park images for now, since they are locked by referrer
        set pat {<img[^>]*src=[\"\']([^\"\']*)[\"\'][^>]*>}
        while {[regexp -nocase $pat $data dummy img]} {
            set img [redirect_image $img $url]
            regsub -all "\\\\" $img {\\\\} img
            regsub -all {&} $img {\\\&} img
            regsub -nocase $pat $data "\n<xxximg src='$img'>\n" data
        }
        regsub -all "<xxximg " $data "<img " data
	regsub -all "	" $data " " data
	regsub -all " +\n" $data "\n" data
	regsub -all "\n +" $data "\n" data
	regsub -all "\n +" $data "\n" data
	regsub -all "\n\n\n+" $data "\n\n" data
	regsub -all "】\n+" $data "】 " data
        save_article 6park $title $url $data
    }
}
