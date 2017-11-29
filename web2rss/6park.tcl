# @rss-nt-adapter@

namespace eval 6park {

    package require ncgi

    proc init {first} {
        variable h
        set h(article_sort_byurl) 1
        set h(lang)  zh
        set h(desc)  留园
        set h(url)   http://www.6park.com
    }

    proc update_index {} {
        ::schedule_read 6park::parse_index http://news.6park.com/newspark/index.php gb2312
    }

    proc parse_index {index_url data} {
        regsub {<div id="d_list"} $data "" data
        regsub {<div id="d_list_foot"} $data "" data

        set list {}

        foreach line [makelist $data <li>] {
            if {[regexp {href="([^>]+)"} $line dummy article_url] &&
                [regexp {>([^<]+)<} $line dummy title]} {
            }

            if {![regexp {nid=([0-9]+)$} $article_url dummy id]} {
                continue;
            }

            regsub ☆ $title "" title
            
            if {![regexp {http[a-z]*://news.toutiaoabc.com} $article_url]} {
                continue
            }

            if {![info exists seen($article_url)]} {
                set seen($article_url) 1
                lappend list [list $article_url $title $id]
            }
        }

        foreach item [lsort -dictionary $list] {
            # Get the oldest article first
            set article_url [lindex $item 0]
            set title       [lindex $item 1]
            set id          [lindex $item 2]
            if {![db_exists 6park $article_url]} {
                ::schedule_read [list 6park::parse_toutiaoabc $id $title] $article_url gb2312
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
        regsub {<table class='xianhua_jidan'.*} $data "" data
        regsub {<a href=[^>]+target=_blank><img[^>]+转发本条新闻到微博'></a>} $data "" data

        set data [sub_block $data "<script" "</script>" ""]
        set data [sub_block $data {<ins class="adsbygoogle"} "</ins>" ""]=
        
        if {"$from" != ""} {
            set data "【$from】 $data"
        }

        # most of the center tags are wrong on 6park
        regsub -all <center> $data <!--noceneter--> data
        regsub -all {align='center'} $data "" data

        # fix images
        regsub -all {onload='javascript:if[(]this.width>600[)] this.width=600'} $data "" data
        if {0} {
            regsub -all "src=\['\"\](\[^> '\"\]+)\['\"\]" $data src=\\1 data

            set pat {<img[^>]*src=(http://[^>]*.popo8.com/[^> ]+)[^>]*>}
            while {[regexp $pat $data dummy img]} {
                set imgfile 6park/foo.jpg
                set h1 http://freednsnow.no-ip.biz/webrss/$imgfile
                
                set i "<img onload='javascript:if(this.width>600) this.width=600' src=XXX border='0'>"
                regsub XXX $i $img img0
                regsub XXX $i http://freednsnow.no-ip.biz/webrss/$imgfile img1
                regsub XXX $i http://127.0.0.1/webrss/$imgfile img2

                regsub $pat $data $img0$img1$img2 data
            }
        }

        regsub -all {<br />.[ 　]+} $data "<br />" data
        regsub -all {<br />.<b>[ 　]+} $data "<br /><b>" data
        
        save_article 6park $title $url $data
    }
}
