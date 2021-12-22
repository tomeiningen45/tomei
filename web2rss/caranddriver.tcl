# @rss-nt-adapter@

namespace eval caranddriver {
    proc init {first} {
        variable h
        set h(article_sort_byurl) 1
        set h(lang)  en
        set h(desc)  {Car and Driver}
        set h(url)   http://www.caranddriver.com
    }

    proc update_index {} {
        ::schedule_read caranddriver::parse_index https://www.caranddriver.com/news/ utf-8
    }

    proc parse_index {index_url data} {
        foreach line [makelist $data {<div class=\"full-item}] {
            if {[regexp {<a href="([^>\"]+)"} $line dummy article_url]} {
                if {[string length $article_url] > 5 && ![db_exists caranddriver $article_url]} {
                    ::schedule_read caranddriver::parse_article https://www.caranddriver.com/$article_url utf-8
                }
            }
        }
    }

    proc parse_article {url data} {
        set title $url
        regexp {<title>([^<]+)</title>} $data dummy title
        regsub {.*<div class="content-header-inner">} $data "" data
        regsub -all {<div class="screen-reader-only">[^<]*</div>} $data "" data

        set data [sub_block $data {<iframe } {</iframe>} ""]
        set data [sub_block $data {<script } {</script>} ""]

        regsub {<div class="deferred-recirculation-module".*} $data "" data
        regsub -all {<div class="breaker-ad-text">Advertisement - Continue Reading Below</div>} $data "" data

        regsub -all {<span class="image-photo-credit">[^<]*</span>} $data "" data
        regsub -all {<span class="image-copyright">[^<]*</span>} $data "" data

        # replace <picture> blocks
        set pic_start {<picture class="">}
        while {[regexp $pic_start $data]} {
            set data [sub_block_single_cmd $data $pic_start {</picture>} caranddriver::picture]
        }

        regsub -all {<div[^>]*>} $data "" data
        regsub -all {</div[^>]*>} $data "" data
        regsub -all {<span[^>]*>} $data "" data
        regsub -all {</span[^>]*>} $data "" data
        regsub -all "\n\[\n \t\r\]+" $data \n\n data

        regsub -all {<a class="editorial-link-item"} $data "<br><li><a " data

        save_article caranddriver $title $url $data
    }

    proc picture {orig} {
        if {[regexp {<source [^=]*srcset=\"([^\"]+)} $orig dummy img]} {
            regsub -all & $img \\\\\\& img
            return "\n<br><img src='$img'><br>\n"
        } else {
            return ""
        }
    }
}
