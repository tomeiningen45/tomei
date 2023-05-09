# @rss-nt-adapter@

namespace eval bringatrailer {
    proc init {first} {
        variable h
        set h(filter_duplicates)  0
        set h(article_sort_byurl) 0
        set h(lang)  en
        set h(desc)  {Bring a Trailer}
        set h(url)   https://bringatrailer.com/auctions
        set h(out)   bringatrailer
        # If more than one posts have the exact same subject, just show one of them
        set h(unique_subject) 1
        # We have one subpage
        set h(subpages) {
            {results { - Results}}
        }
	set h(max_articles) 200
    }

    proc update_index {} {
       #schedule_index https://bringatrailer.com/auctions/
        schedule_index https://bringatrailer.com/auctions/results/
    }

    proc schedule_index {index_url} {
        ::schedule_read [list bringatrailer::parse_index] $index_url
    }

    proc parse_index {index_url data} {
	set list {}
	set is_result 0
	if {[regexp /results/ $index_url]} {
	    set is_result 1

	    if {[regsub {.*var auctionsCompletedInitialData} $data "" data] &&
		[regsub {listings-completed-toolbar-tmpl.*} $data "" data]} {
		foreach line [makelist $data {"active":false}] {
		    if {![regexp {"url":"([^"]+)} $line dummy article_url]} {
			continue
		    }
		    regsub -all \\\\ $article_url "" article_url
		    if {[regexp {"timestamp_end":([0-9]+)} $line dummy pubdate]} {
			set date($article_url) $pubdate
			puts $pubdate
		    } else {
			set date($article_url) [clock seconds]
		    }
		    if {![db_exists bringatrailer $article_url] && ![info exists seen($article_url)]} {
			set seen($article_url) 1
			set list [concat $article_url $list]
		    }
		}
            }
	} else {
	    foreach line [makelist $data {<div class="auctions-item-container"}] {
		if {[regexp {data-timestamp="([0-9]+)"} $line dummy id] &&
		    [regexp {<a class="auctions-item-image-link" href=\"([^\"]+)\">} $line dummy article_url]} {
		    set table($id) $article_url
		}
	    }
	    set n 20
	    foreach id [lsort -integer -decreasing [array names table]] {
		set article_url $table($id)
		if {![db_exists bringatrailer $article_url]} {
		    set list [concat $article_url $list]
		}
		incr n -1
		if {$n < 0} {
		    break
		}
	    }
	}

	foreach article_url $list {
	    puts $article_url
	}

	set pubdate [expr [clock seconds] - [llength $list]]
	foreach article_url $list {
	    # oldest first
	    ::schedule_read [list bringatrailer::parse_article $is_result $date($article_url)] $article_url
	    incr pubdate
	}
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list bringatrailer::parse_article 0 [clock seconds]] $url
    }
    
    proc parse_article {is_result pubdate url data} {
        global g

	set bidto ""
	if {[regexp {Bid to <strong>([^<]+)</strong>} $data dummy bidto]} {
	    #set bidto " Bid to $bidto"
	}
	
	set miles ""
	if {[regexp {<li>Chassis: <a[^>]*>[^<]*</a></li><li>([^<]+)</li>} $data dummy miles]} {
	    regsub { Shown, TMU} $miles "" miles
	    regsub { Shown} $miles "" miles
	    regsub { Indicated} $miles "" miles
	    set miles " $miles"
	}
	
	set title ""
	if {[regexp {<title>([^<]+)</title>} $data dummy title]} {
	    regsub {No Reserve: } $title "" title
	    regsub {[0-9,]+-Mile } $title "" title
	    regsub {[0-9,]+k-Mile } $title "" title
	    regsub { for sale on BaT Auctions} $title $miles title
	    regsub { .Lot #.*} $title "" title
	    if {![regexp {[$]} $title]} {
		regsub {[-] closed on} $title "- closed, bid to $bidto on" title
	    }
	}

        set mainimg ""
        if {[regexp {<img [^>]*class="post-image wp-post-image"[^>]*>} $data mainimg]} {
            append mainimg <p>
        }

        set essen ""

        if {[regexp {<h2 class="title">BaT Essentials</h2>(.*<strong>Lot</strong>[^<]*</div></div>)} $data dummy essen]} {
            append essen <hr>
        }

	regsub {<div id="bat_listing_page_video_gallery".*} $data "" data
	regsub {.*<div class="post-excerpt">} $data "" data
	regsub {<script type.*} $data "" data
	set subpage {}

        set data $mainimg$essen$data


	if {$is_result} {
	    set subpage results
	}
	set data "[download_timestamp $pubdate]$data"
	save_article bringatrailer $title $url $data $pubdate $subpage
    }
}

