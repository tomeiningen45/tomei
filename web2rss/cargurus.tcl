# @rss-nt-adapter@

namespace eval cargurus {
    proc init {first} {
        variable h
        set h(article_sort_byurl) 1
        set h(lang)  en
        set h(desc)  {Cargurus}
        set h(url)   http://www.cargurus.com
    }

    proc update_index {} {
	global g

	set terms {
	    # General
	    &distance=50&maxPrice=20000&maxMileage=150000
	    # 370z
	    &distance=100&maxPrice=30000&maxMileage=150000&entitySelectingHelper.selectedEntity=d2018
	    # 350z
	    &distance=100&maxPrice=30000&maxMileage=150000&entitySelectingHelper.selectedEntity=d236
	    # Mustang
	    &distance=100&maxPrice=30000&maxMileage=150000&entitySelectingHelper.selectedEntity=d2
	    # Cube
	    &distance=50000&entitySelectingHelper.selectedEntity=d1764
	    # xB
	    &distance=500&entitySelectingHelper.selectedEntity=d435
	    # All Hondas
	    &distance=100&maxPrice=30000&entitySelectingHelper.selectedEntity=m6
	    # All Acuras
	    &distance=100&maxPrice=30000&entitySelectingHelper.selectedEntity=m4
	    # All Toyotas
	    &distance=100&maxPrice=30000&entitySelectingHelper.selectedEntity=m7
	    # All Scions
	    &distance=100&maxPrice=30000&entitySelectingHelper.selectedEntity=m52
	    # All Nissans
	    &distance=50&maxPrice=30000&entitySelectingHelper.selectedEntity=m12
	    # All Mazdas
	    &distance=100&maxPrice=30000&entitySelectingHelper.selectedEntity=m42
	    # All Fords
	    &distance=50&maxPrice=30000&entitySelectingHelper.selectedEntity=m2
	}

	regsub -all "#\[^\n\]*" $terms "" terms
	set base https://www.cargurus.com/Cars/searchResults.action?zip=$g(zipcode)
	append base &inventorySearchWidgetType=AUTO&transmission=M
	append base &nonShippableBaseline=0&sortDir=ASC&sourceContext=carGurusHomePage_false_0
	append base &sortType=AGE_IN_DAYS&offset=0&maxResults=35&filtersModified=true

	foreach t $terms {
	    set url ${base}${t}
	    ::schedule_read cargurus::parse_index $url
	}
    }

    proc format_info {prefix field {fieldname {}}} {
	upvar map map
	if {$fieldname == {}} {
	    set fieldname [string toupper [string index $field 0]][string tolower [string range $field 1 end]]
	}
	set data ""
	catch {
	    set data "<tr><td><b>$fieldname:</b>&nbsp;</td> <td>$map($prefix/$field)</td></tr>\n"
	}
	return $data
    }

    proc parse_index {index_url data} {
	json_to_map $data map

	set maxdist 50
	regexp {[^a-zA-Z]distance=([0-9]+)} $index_url dummy maxdist

	for {set i 0} {true} {incr i} {
	    set prefix /$i
	    if {![info exists map($prefix/id)]} {
		break
	    }
	    set article_url https://www.cargurus.com/Cars/link/$map($prefix/id)
	    if {[db_exists cargurus $article_url]} {
		continue
	    }
	    if {[catch {
		set price ""
		set miles ""
		catch {
		    set price " \$$map($prefix/price)"
		}
		catch {
		    set miles " @ $map($prefix/mileage) miles"
		}
		set dist 10000000
		catch {
		    set dist $map($prefix/distance)
		}
		set days 0
		catch {
		    set days $map($prefix/daysOnMarket)
		}
		set accd 0
		catch {
		    set accd $map($prefix/accidentCount)
		}
		set title "$map($prefix/listingTitle)$price$miles"
		set data ""
		set img ""
		catch {
		    set img $map($prefix/originalPictureUrl)
		    regsub "https //" $img "https://" img
		    regsub "http //"  $img "http://"  img
		    append data "<img src=$img><p>\n"
		}
		if {$img == {} || $price == {}} {
		    # not ready yet. Try again later.
		    continue
		}
		if {$accd > 0} {
		    continue
		}
		if {$dist > $maxdist} {
		    continue
		}
		if {$days <= 0 && 0} {
		    # Wait one day to make sure data/photo is available
		    continue
		}
		append data "<table>\n"
		append data [format_info $prefix mileage]
		append data [format_info $prefix price]
		append data [format_info $prefix expectedPrice {Expected Price}]
		append data [format_info $prefix priceDifferential {Price Diff}]
		append data [format_info $prefix daysOnMarket {Days on Market}]
	        append data [format_info $prefix carYear Year]
	        append data [format_info $prefix ownerCount Owners]
	        append data [format_info $prefix dealRating {Deal Rating}]
		append data [format_info $prefix sellerCity {Location}]
		append data [format_info $prefix distance]
		append data [format_info $prefix sellerType {Seller Type}]
		append data [format_info $prefix sellerRegion {Seller State}]
		append data [format_info $prefix sellerCity {Location}]
		append data [format_info $prefix phoneNumber {Phone Number}]
		append data [format_info $prefix sellerRating {Seller Rating}]
		append data [format_info $prefix reviewCount {Number of Reviews}]
		append data [format_info $prefix structuredDataDealerName {Dealer}]
		append data [format_info $prefix makeName {Make}]
		append data [format_info $prefix modelName {Model}]
		append data [format_info $prefix localizedTransmission Transmission]
		append data [format_info $prefix accidentCount {Accidents}]
		append data [format_info $prefix options]

		append data </table>

		save_article cargurus $title $article_url $data
		#puts $title
	    } error]} {
		#puts "$error"
	    }
	}
    }

    proc debug_article_parser {url} {
        ::schedule_read cargurus::parse_article $url utf-8
    }

    proc parse_article {url data} {
	puts "Not supported"
    }
}
