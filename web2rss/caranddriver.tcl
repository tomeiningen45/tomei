# @(disabled)rss-nt-adapter@

namespace eval caranddriver {
    proc init {first} {
        variable h
        set h(article_sort_byurl) 1
        set h(lang)  en
        set h(desc)  {Car and Driver}
        set h(url)   http://www.caranddriver.com
    }

    proc update_index {} {
        atom_update_index caranddriver https://www.caranddriver.com/rss/all.xml/
    }

    proc parse_link {link} {
	if {[regexp shopping-advice $link]} {
	    return ""
	}
	if {[regexp gallery $link]} {
	    return ""
	}
	return $link
    }

    proc debug_article_parser {url} {
        ::schedule_read [list caranddriver::parse_article [clock seconds]] $url utf-8
    }

    proc parse_gallery {pubdate url data} {
	set title $url
	regsub -all {="[^"]*"} "%%%%" data
	regsub -all {<[^>]*>} $data "======" data
        regexp {<title>([^<]+)</title>} $data dummy title
	puts hello
        save_article caranddriver $title $url $data
    }
    
    proc parse_article {pubdate url data} {
	if {[regexp {gallery/$} $url]} {
	    parse_gallery $pubdate $url $data
	    return
	}
	set title $url

        regexp {<title>([^<]+)</title>} $data dummy title
        regsub {.*<h1[^>]*>[^<]*</h1>} $data "" data

	regsub {.*<div class=.article-body-content} $data "<div " data
        regsub {.*<div class="content-header-inner">} $data "" data
        regsub -all {<div class="screen-reader-only">[^<]*</div>} $data "" data

        set data [sub_block $data {<iframe } {</iframe>} ""]
	set data [sub_block $data {<style } {</style>} "\n"]
        set data [sub_block $data {<script } {</script>} ""]

        regsub {<div class="deferred-recirculation-module".*} $data "" data
	regsub {<a href=./author/.*} $data "" data
	
        regsub -all {<div class="breaker-ad-text">Advertisement - Continue Reading Below</div>} $data "" data

        regsub -all {<span class="image-photo-credit">[^<]*</span>} $data "" data
        regsub -all {<span class="image-copyright">[^<]*</span>} $data "" data

        regsub -all {<img [^>]*data-src="([^>\"]*)"[^>]*>} $data "<img width='100%' src='\\1'>" data

        # replace <picture> blocks
        set pic_start {<picture class="[^>]*">}
        set pic_end   {</picture>}
        while {[regexp ${pic_start}.*${pic_end} $data]} {
            set d [sub_block_single_cmd $data $pic_start $pic_end caranddriver::picture]
            if {"$d" == "$data"} {
                break
            } else {
                set data $d
            }
        }

        regsub -all {<div[^>]*>} $data "" data
        regsub -all {</div[^>]*>} $data "" data
        regsub -all {<span[^>]*>} $data "" data
        regsub -all {</span[^>]*>} $data "" data
        regsub -all "\n\[\n \t\r\]+" $data \n\n data

        regsub -all {<a class="editorial-link-item"} $data "<br><a " data

        regsub {<!-- shared/end-of-content.twig -->.*} $data "" data

        regsub {<button class="mobile-adhesion-unit-close-button"></button>.*} $data "" data

        regsub {<img [^>]*hips.hearstapps.com/rover/profile_photos/[^>]*>} $data "" data
	regsub -all {<p [^>]*>} $data "<p>\n" data

        save_article caranddriver $title $url $data
    }

    proc picture {orig} {
        if {[regexp {<source [^=]*srcset=\"([^\"]+)} $orig dummy img]} {
            regsub -all & $img \\\\\\& img
            return "\n<br><img width='100%' src='$img'><br>\n"
        } else {
            return ""
        }
    }
}
