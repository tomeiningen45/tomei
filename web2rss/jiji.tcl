# @rss-nt-adapter@

namespace eval jiji {
    proc init {first} {
        variable h
        set h(article_sort_byurl) 0
        set h(lang)  en
        set h(desc)  {時事通信}
        set h(url)   https://www.jiji.com/
        set h(out)   jiji
    }

    proc update_index {} {
	global jiji_pending
	catch {
	    unset jiji_pending
	}
	::schedule_read [list jiji::parse_index 30] https://www.jiji.com/jc/list?g=soc utf-8
	::schedule_read [list jiji::parse_index 30] https://www.jiji.com/jc/list?g=int utf-8
	::schedule_read [list jiji::parse_index 10] https://www.jiji.com/jc/list?g=afp utf-8
	::schedule_read [list jiji::parse_index 30] https://www.jiji.com/jc/list?g=eco utf-8
    }

    proc parse_index {limit index_url data} {
	global
	set list {}
	puts [string length $data]

        foreach line [makelist $data {<a href=\"}] {
            if {[regexp {^/jc/article[?]k=[0-9a-z]+} $line link]} {
		lappend list https://www.jiji.com$link
	    }
	}

	set list [lsort -dictionary $list]
	set len [llength $list]
	if {$len > $limit} {
	    set list [lrange $list [expr $len - $limit] end]
	}
	
        foreach article_url $list {
            if {![db_exists jiji $article_url] &&
		![info exist jiji_pending($article_url)]} {
		set jiji_pending($article_url) 1
                ::schedule_read jiji::parse_article $article_url utf-8
                incr n
                if {$n > 30} {
                    # dont access the web site too heavily
                    break
                }
            }
        }
    }


    proc debug_article_parser {url} {
        ::schedule_read jiji::parse_article $url utf-8
    }

    proc parse_article {url data} {
	set title "$url"
	regexp {<title>([^<]+)</title>} $data dummy title
	regsub {：時事ドットコム} $title "" title
	set pubdate [clock seconds]

	if {[regexp {"datePublished":"([^\"]+)"} $data dummy date]} {
	    #puts $date
	    regsub {[+-][0-9:]+$} $date "" date
	    catch {
		set pubdate [clock scan $date]
		# convert from Japan time
		incr pubdate [expr -16 * 60 * 60]
		#puts [clock format $pubdate]
	    }
	}

	if {![regsub {.*<div class="ArticleText clearfix">} $data "" data] ||
	    ![regsub {</article>.*} $data "" data]} {
	    set data "Content layout has changed"
	}

	set data [sub_block $data {<script[^>]*>} </script> ""]
	regsub -all {<img src="/news2/kiji_photos/square/dummy/dummy2.png"[^>]*>} $data "" data
	regsub -all {<img src="/} $data {<img src="https://www.jiji.com/} data 
	regsub -all {<a href="[^>]*rel=pv">} $data "" data
	set data "[download_timestamp $pubdate]${data}"

	regsub -all {<![^>]*>} $data "" data	
	regsub -all {<aside[^>]*>} $data "" data	
	regsub -all {</aside[^>]*>} $data "" data	
	regsub -all {<div[^>]*>} $data "" data	
	regsub -all {</div[^>]*>} $data "" data
	regsub -all "\[ \t]+\n" $data \n data
	regsub -all "\n\[ \t]+" $data \n data
	regsub -all "\n\n+" $data \n data

	set data [redirect_images https://www.jiji.com/ $data]

	if {![regexp {<img} $data]} {
	    if {[clock seconds] - $pubdate < 3600} {
		# Jiji.com sometimes updates the article with more contents and image. Wait for it.
		puts "Waiting for image $url"
		return
	    }
	}

	if {![regexp "<img " $data]} {
	    append data "\n<img src=/webrss/jijitsushin_200x200.jpg>"
	}
	
        save_article jiji $title $url $data $pubdate
    }
}
