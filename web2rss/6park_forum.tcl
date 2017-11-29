# @rss-nt-lib@

namespace eval 6park_forum {
    proc parse_index {forum index_url data} {
        regsub {<div id="d_list"} $data "" data
        regsub {<div id="d_list_foot"} $data "" data

        foreach line [makelist $data {(<ul>.			<li>)|(<br></li><li><a)}] {
            if {[regexp {href="([^>]+)"} $line dummy link] &&
                [regexp {>([^<]+)<} $line dummy title]} {
                set link $index_url/$link
                #puts $title==$link
            }

            if {![regexp {tid=([0-9]+)$} $link dummy id]} {
                continue;
            }

            lappend list [list $link $title]
        }

        foreach item [lsort -dictionary $list] {
            # Get the oldest article first
            set article_url [lindex $item 0]
            set title       [lindex $item 1]
            if {![db_exists $forum $article_url]} {
                ::schedule_read [list 6park_forum::parse_article $forum $title] $article_url gb2312
                incr n
                if {$n > 10} {
                    # dont access the web site too heavily
                    break
                }
            }
        }
    }

    proc parse_article {forum title url data} {
        regsub {.*<!--bodybegin-->} $data "" data
        regsub {<!--bodyend-->.*} $data "" data
        regsub -all {<font color=E6E6DD> www.6park.com</font>} $data "\n\n" data
        regsub -all {onclick=document.location=} $data "xx=" data
        regsub -all {onload[ ]*=} $data "xx=" data
        regsub {.*</script>} $data "" data 
        regsub -all {<h2 [^>]+>} $data "<h2>" data
        regsub -all { style="[^\"]*"} $data "" data
        # most of the center tags are wrong on 6park
        regsub -all <center> $data <!--noceneter--> data
        regsub -all {align=.center.} $data "" data
        regsub {<h1 class="[^\"]+">[^<]+</h1>} $data "" data
        regsub {<h1 id="[^\"]+">[^<]+</h1>} $data "" data
        regsub {<h1>((<font[^>]*>)|)[^<]+<span class="[^\"]+"></span>((</font>)|)</h1>} $data "" data
            
        # fix images
        # regsub -all "src=\['\"\](\[^> '\"\]+)\['\"\]" $data src=\\1 data
        
        if {[regexp <pre> $data] && ![regexp </pre> $data]} {
            regsub <pre> $data " " data
        }
        regsub -all "<img " $data " <img " data

        save_article $forum $title $url $data
    }
}
