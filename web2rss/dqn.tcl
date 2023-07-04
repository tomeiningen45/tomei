# @rss-nt-adapter@

namespace eval dqn {
    proc init {first} {
        variable h
        set h(filter_duplicates)  0
        set h(article_sort_byurl) 0
        set h(delay:article) [expr 60 * 60 * 1000]
        set h(lang)  jp
        set h(desc)  痛いニュース(ﾉ∀`)
        set h(url)   http://blog.livedoor.jp/dqnplus/
        set h(out)   dqn
    }

    proc update_index {} {
        rdf_update_index dqn http://blog.livedoor.jp/dqnplus/index.rdf euc-jp
        rdf_update_index dqn http://hamusoku.com/index.rdf
    }

    proc parse_link {link} {
        return $link
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list dqn::parse_article [clock seconds]] $url
    }

    proc parse_article {pubdate url data} {
	if {[regexp hamusoku.com $url]} {
	    if {![regexp {<span class="comment-body">} $data]} {
		# comments no yet available?
		return
	    }

	}

        set title "??"
        regexp {<title>([^<|]+)} $data dummy title
 
        set extra ""
        if {[regsub "痛いニュース\[^:\]*: " $title "" title]} {
            set extra "(痛)"
	    set defimg https://livedoor.blogimg.jp/dqnplus/imgs/b/0/b0613243.png
        } else {
	    set defimg https://livedoor.blogimg.jp/hamusoku/imgs/e/f/ef3b3b00.jpg
	}
	
        regsub " - ライブドアブログ" $title "" title
        if {[regsub ":ハムスター速報" $title "" title]} {
            set extra "(ハ)"
        }
        set title $extra$title

        set moto ""
        if {[regexp "元スレ.(http\[^< \n\]+)" $data dummy moto]} {
            set moto "元スレ: <a href='$moto'>$moto</a><p>\n\n"
        }

	if {[regexp hamusoku.com $url]} {
	    regsub -all ":</span><span \[^\n\]*<span class=\"comment-body\">" $data ":</span><span>" data
	}

        regsub {.*<div class="main entry-content">} $data "" data
        regsub {<div class=posted>.*} $data "" data

        regsub {.*<div class="article-category-outer">} $data "" data
       #regsub {.*<div class="article-body-more">} $data "" data
        regsub {.*<h1 class="article-title entry-title">} $data "" data
       #regsub {<div id="ad2">.*} $data "" data
        regsub {<h3>「話題」カテゴリの最新記事</h3>.*} $data "" data
        regsub {<b>ハム速公式twitter<br>.*} $data "" data

        set data [sub_block $data "<script" "</script>" ""]
        set data [sub_block $data "<iframe" "</iframe>" ""]

        regsub -all {<div class="t_h"[^>]*>} $data "\n<br>" data
        regsub -all {ID:<span class="id"><b>[^<]+</b></span>} $data "ID:xxx" data

        regsub -all {<div[^>]*>} $data "\n" data
        regsub -all {</div[^>]*>} $data "" data

        regsub -all {<span style=[^>]*>[^<]+</span> <span style=[^>]*> 202[0-9]/[0-9]+/[0-9]+[^<]*ID:[^<]*</span>} $data "" data

        regsub -nocase -all {<span[^>]*>} $data "\n" data
        regsub -nocase -all {</span[^>]*>} $data "" data

        regsub -all {<font color="green"><strong>[^<]+</strong></font>[^<]*202[0-9]年[0-9]+月[0-9]+日[^<]*ID：[^<]*<br>} $data "" data
        regsub -all {<font color="green"><b>[^<]+</b>[^<]*</font>:202[0-9]/[0-9]+/[0-9]+[^<]*ID:[^<]*<br>} $data "" data

       #regsub -all "<br>\[ \n\]*</strong><br>" $data "</strong><br>" data
        regsub -all "<br>(\[ \n\]*<br>)+" $data "<br>\n" data

        regsub -all {<a href=.https://www.amazon.co[^<]+</a>} $data "" data
        regsub -all {<a href=.https://www.amazon.co[^<]+<img[^<]+</a>} $data "" data

        regsub -all {<dl class="article-category"><dt>カテゴリ</dt><dd class="article-category"><a[^<]+</a></dd></dl>} $data "" data

        regsub -all {<![^>]*>} $data "" data
        set spc "\[\n \t\]"
        regsub -all "${spc}${spc}${spc}+" $data \n\n data

        set data "$moto$data"

	if {![regexp "<img " $data]} {
	    append data "\n<img src=\"$defimg\">"
	}
	
        save_article dqn $title $url $data $pubdate
    }
}
