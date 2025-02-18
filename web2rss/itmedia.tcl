# @rss-nt-adapter@

namespace eval itmedia {
    proc init {first} {
        variable h
        set h(filter_duplicates)  0
        set h(article_sort_byurl) 0
        set h(lang)  jp
        set h(desc)  {ITmedia NEWS}
        set h(url)   https://www.itmedia.co.jp/news
        set h(out)   itmedia
    }

    proc update_index {} {
        atom_update_index itmedia https://rss.itmedia.co.jp/rss/2.0/news_bursts.xml shiftjis
    }

    proc parse_link {link} {
        return $link
    }

    # this function is called when ./test.sh has a non-empty DEBUG_ARTICLE
    proc debug_article_parser {url} {
        ::schedule_read [list itmedia::parse_article [clock seconds]] $url shiftjis
    }

    proc parse_article {pubdate url data} {
        set title "??"
        regexp {<title>([^<|]+)} $data dummy title
        regsub " - ITmedia NEWS" $title "" title

        regsub {.*<!-- cmsHoleBodyStart -->} $data "" data
        regsub {<!-- cmsBodyMainEnd -->.*} $data "" data
        regsub -all \u001a $data "" data

	set data [redirect_images https://www.itmedia.co.jp/news $data]
        save_article itmedia $title $url $data $pubdate
    }
}
