# @rss-nt-adapter@

namespace eval fishing {
    proc init {first} {
        variable h
        set h(article_sort_byurl) 0
        set h(lang)  en
        set h(desc)  Fishing
	set h(url)   https://forecast.weather.gov/shmrn.php?mz=pzz535&syn=pzz500
    }

    proc update_index {} {
        ::schedule_read fishing::parse_noaa https://forecast.weather.gov/shmrn.php?mz=pzz535&syn=pzz500 utf-8
	::schedule_read fishing::parse_bayside https://baysidemarinesc.com/ utf-8
    }

    proc parse_noaa {index_url data} {
	set zone pzz535
	set pubdate ""
	if {[regexp {<strong><font size=".." color="#483D8B">&nbsp;([^<]+)</font></strong>} $data dummy date]} {
	    if {[regexp {([0-9]+)([0-9][0-9]) (..) (...) (.*) ([0-9]+)} $date dummy h m half tz last year]} {
		if {"$half" == "PM"} {
		    incr h 12
		}
		catch {
		    set pubdate "$last $h:$m:00 $tz $year"
		    set pubdate [clock scan $pubdate]
		}
	    }	    
	}

	if {$pubdate != ""} {
	    set title "Monterey Bay Forecast [clock format $pubdate -format {%b %d %H:%M}]"
	    set id zone-[clock format $pubdate -format {%Y%m%d-%H%M00}]
	    set article_url ${index_url}&id=$id

	    if {![db_exists fishing $article_url]} {
		regsub {.*<!-- main content -->} $data "" data
		regsub {.*<div style="font-family: Fixed, monospace[^>]+>} $data "" data
	    	regsub {<div id="footer.*} $data "" data

		regsub -all "&nbsp;" $data "" data
		regsub -all "\n\n" $data "<p>\n\n" data
		regsub -all "</strong>" $data "</strong><br>" data
		regsub -all {[.][.][.]} $data ", " data
		regsub {[.]Synopsis for the} $data "" data

		regsub -all {[$][$]<p>} $data "" data
		regsub -all {[$][$]} $data "" data
		regsub -all {<hr><p>} $data "" data
		regsub -all {<hr />} $data "" data
		regsub "PZZ...........\n(\[^\n]+)\n<strong>\[^\n]+" $data "" data
		regsub "PZZ...........\n<strong>\[^\n]+" $data "" data
		regsub -all {, <p>} $data ".<p>" data

		regsub -all { rain} $data " <font color=#800000><b>rain</b></font>" data
		regsub -all {size=".1"} $data "" data
		regsub -all "\n\n\n+" $data "\n\n" data
		regsub "</div></div><p>\[\n \]+\$" $data "" data

		append data "\n<img src='https://library.noaa.gov/portals/1/external-content.duckduckgo.com.jpg'>"
		save_article fishing $title $article_url $data $pubdate
	    }
	}
    }

    proc parse_bayside {index_url data} {
	set imgs ""
	if {[regsub {.*<img SRC="logo.gif"} $data "" rest]} {
	    foreach item [makelist $rest {<p><img src="}] {
		if {[regexp {^[^>]+[.]jpg} $item image]} {
		    append imgs "<img src=https://baysidemarinesc.com/$image><br>$image<p>\n"
		}
	    }
	}
	
	set lines [split $data "\n"]
	set i 0
	foreach line $lines {
	    incr i
	    if {[regexp "^      (\[^<\]+)<br />" $line dummy pubdate]} {
		set news [string trim [lindex $lines $i]]
		regsub "&amp;" $pubdate " and " pubdate
		set title "Bayside Marine Report $pubdate"
		regsub -all " " $pubdate "-" pubdate

		set article_url https://baysidemarinesc.com/?&id=$pubdate

		if {![db_exists fishing $article_url]} {
		    save_article fishing $title $article_url "$news<p>\n$imgs"
		}
		return
	    }
	}
    }
}
