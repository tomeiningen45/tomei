# @rss-nt-adapter@

namespace eval yahoofn {
    proc init {first} {
        variable h
        set h(article_sort_byurl) 0
        set h(lang)  en
        set h(desc)  {YF}
        set h(url)   https://finance.yahoo.com
        set h(out)   yahoofn
    }

    proc update_index {} {
        atom_update_index yahoofn https://finance.yahoo.com/news/rssindex
    }

    proc parse_link {link} {
	if {![regexp finance.yahoo.com $link]} {
	    return ""
	}
	return $link
    }

    proc debug_article_parser {url} {
        ::schedule_read [list yahoofn::parse_article [clock seconds]] $url utf-8
    }

    proc parse_article {pubdate url data} {
	set title "$url"
	regexp {<title>([^<]+)</title>} $data dummy title
	
	regsub {.*<div class="caas-body">} $data <div> data
	regsub {<aside class="caas-aside-section">.*} $data "" data

	regsub -all {<img[^>]*data-src=} $data "<img src=" data
	set data [sub_block $data {<iframe } {</iframe>} ""]
	set data [sub_block $data {<style } {</style>} "\n"]
        set data [sub_block $data {<script } {</script>} ""]
        set data [sub_block $data {<noscript} {</noscript>} "\n"]

	regsub -all {<div class=[^>]*blocked[^>]*>} $data {<DIV style="display:none">} data
	regsub -all {<svg[^>]*>} $data "" data
	regsub -all <u> $data "" data
	regsub -all </u> $data "" data
	regsub -all {<a href=[^>]*><strong>[^<a-z]*</strong>} $data "\n" data

	regsub {<button[^>]*>Story continues</button>} $data "" data

	regsub -all {<div[^>]*>} $data "\n<div>" data
	#regsub -all "<div" $data "\n<nodiv" data
	#regsub -all "</p>" $data "" data
	#regsub -all "<p>(\n</a><p>)+" $data "<p>" data

	set data "<i>Published [date_string $pubdate]; Downloaded [date_string]</i><br>$data"
        save_article yahoofn $title $url $data $pubdate
    }
}
