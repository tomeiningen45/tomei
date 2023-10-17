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
	::schedule_read fishing::parse_nba https://www.sportsmediawatch.com/nba-tv-schedule-2023-how-to-watch-stream-games-today/ utf-8
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

	if {[regsub {.*<td WIDTH="371" HEIGHT="1608" VALIGN=baseline>} $data "" data]} {
	    set list [split $data "\n"]
	    set all {}
	    for {set i 0} {$i < 25} {incr i} {
		append all [lindex $list $i]\n
	    }
	    set data $all
	} else {
	    set data "site data has changed. Please check"
	}

	regsub {</strong>Need a license. Get it online at</h2>} $data "" data
    	regsub {<h2 align="center"> https://www.ca.wildlifelicense.com/InternetSales/</h2>} $data "" data
    	regsub {<h2 align="center">IF YOU ARE SICK STAY HOME DONT COME! <br />} $data "" data
	regsub {<h2 align="center"><strong> ON 5-01-2023 WE WILL OPEN 6-5 DAILY <br>} $data "" data
	regsub {<h2 align="center">SALMON SEASON CLOSED FOR 2023!<br />} $data "" data
	regsub {MAY 15 CRAB FISHING IS BACK TO HOOPS AND LOOPS AND NO TRAPS UNTIL 6-30-23 .<br /> } $data "" data
	
	regsub -all {<h2 align="center">} $data "" data
	regsub -all {<p align="center">&nbsp;</p>} $data "" data
	regsub "In another emergency action, the Commission voted unanimously to reduce the daily bag and possession limit for California halibut from three fish to two fish in California waters north of Point Sur, Monterey County. The regulations are expected to take effect June 1, 2023. The reduced California halibut limit is designed to protect the resource amid increased recreational fishing pressure due to limited fishing opportunities and changes in other ocean fisheries including salmon. The Pacific halibut fishery is unaffected by the Commission&rsquo;s action; the daily bag and possession limit for Pacific halibut remains one fish with no size limit.&nbsp;</h2>" $data "" data

	regsub -all {<br />} $data <br> data
	regsub -all "(\[^\n\]*\[0-9\]+<br>)" $data <p><b>\\1</b> data
	regsub -all "  +<br>" $data "" data
	regsub "^\[ \t\n\r\]*" $data "" data
	
	regsub {.*<div class="style2">} $data "" data
	set md5 [::md5::md5 -hex $data]
	
	set title "Bayside Marine - [clock format [clock seconds] -format {%Y %b %d}]"

	set article_url https://baysidemarinesc.com/?&id=$md5

	puts $md5
	
	if {![db_exists fishing $article_url]} {
	    save_article fishing $title $article_url "$data<p>\n$imgs"
	}
    }

    proc parse_nba {index_url data} {
	puts $index_url
	if {![regsub {.*<div id="selectdate">} $data "" data]} {
	    return
	}
	regsub {<div class=“previousgames”>.*} $data "" data
	regsub -all {, ESPN Radio} $data "" data
	regsub -all {ESPN Radio} $data "" data

	set title "NBA Games for [clock format [clock seconds] -format %y/%m/%d]"
	set out $title
	set n 0
	foreach item [makelist $data {<span class="bold"><a name="[^>]*">}] {
	    if {[info exists done]} {
		break
	    }
	    if {[regexp {^([^<]+)<} $item dummy date]} {
		set need_date 1
		foreach row [makelist $item {<tr>}] {
		    regsub -all {<a[^>]*>} $row "" row
		    regsub -all {</a[^>]*>} $row "" row
		    set nat ""
		    set local ""
		    if {[regexp {<td>([0-9]+:[0-9]+ [^<]+)</td><td>([^<]+)</td><td>([^<]*)</td>} $row dummy \
			     time teams nat local]} {
			set ok 0
			if {[regexp {(TNT)|(ESPN)|(ABC)} $nat]} {
			    set ok 1
			}
			if {[regexp NBCSBA $local]} {
			    set ok 1
			}
			if {$ok} {
			    if {$need_date} {
				append out "\n<p><b>$date</b><br>\n"
				set need_date 0
			    }
			    append out "$time...$teams...$nat...$local<br>\n"
			    incr n
			    if {$n > 30} {
				set done 1
				break
			    }
			}
		    }
		}
	    }
	}

	set md5 [::md5::md5 -hex $out]
	set article_url "$index_url?&id=$md5"

	if {![db_exists fishing $article_url]} {
	    save_article fishing $title $article_url "$out<p>\n<img src=https://www.sportsmediawatch.com/wp-content/uploads/2022/04/smwpodcastlogo-350x250.webp>"
	}
    }
}
