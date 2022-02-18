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
	schedule_index https://bringatrailer.com/auctions/
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

	    regsub {.*<div class="auction-results">} $data "" data
	    foreach line [makelist $data {https:././bringatrailer.com./listing}] {
		if {[regexp {^./([^/]+)./} $line dummy id]} {
		    set article_url https://bringatrailer.com/listing/$id/
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
	#exit

	set pubdate [expr [clock seconds] - [llength $list]]
	foreach article_url $list {
	    # oldest first
	    ::schedule_read [list bringatrailer::parse_article $is_result $pubdate] $article_url
	    incr pubdate
	}
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list bringatrailer::parse_article 0 [clock seconds]] $url
    }
    
    proc parse_article {is_result pubdate url data} {
        global g

        set title ""
	if {[regexp {<title>([^<]+)</title>} $data dummy title]} {
	    regsub {No Reserve: } $title "" title
	    regsub { for sale on BaT Auctions} $title "" title
	    regsub { .Lot #.*} $title "" title
	}

	regsub {<div id="bat_listing_page_video_gallery".*} $data "" data
	regsub {.*<div class="post-excerpt">} $data "" data
	regsub {<script type.*} $data "" data
	set subpage {}

	if {$is_result} {
	    set subpage results
	}
	save_article bringatrailer $title $url $data $pubdate $subpage
    }
}

