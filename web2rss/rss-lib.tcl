#package require ncgi

proc clock_format {date} {
    return [clock format $date -format {%a, %d %b %Y %T %Z}]
}

proc storage_root {} {
    
    foreach d {
        /opt/local/www/apache2/html/webrss
        /usr/local/var/www/webrss
        /var/www/html/webrss
    } {
        if {[file exists $d] && [file isdir $d]} {
            return $d
        }
    }

    set a /tmp/webrss
    file mkdir $a
    return $a
}


set g(webroot) ""

proc redirect_image {img referrer} {
    global g

    set pat {[@^]}
    if {[regexp $pat $img] || [regexp $pat $referrer]} {
        return ""
    }

    set s [ncgi::encode $img^$referrer].jpg
    regsub -all {%2F} $s "@" s

    return $g(webroot)/hooks/im2/$s
}


# The opposite of "enclose"
proc declose {data {n 1}} {
    set len [string length $data]
    set data [string range $data $n [expr $len - 2 * $n]]
    return $data
}

# Poor man's JSON parsing
proc json_to_map {data mapname {prefix {}}} {
    upvar $mapname map
    set mapname map

    # Convert the [] and {}
    # :{id:val,id:val}     = simple property list
    #     => {-id val id val-}
    # :[elm, elm, elm]     = simple enumerated array -> treated as simple tcl array
    #     => { elm elm elm } 
    # :[{id1:val,id2:val},{id1:val,id2:val}]  = treated as :{"1":{id1:val,id2:val},"2":{id1:val,id2:val}}
    #     => {[{- elm elm elm -}]} 

    set data [string trim $data]

    if {"$prefix" == ""} {
	regsub -all "\}," $data "\} " data

	regsub -all "\\\[\{" $data "\ufff0" data
	regsub -all "\}\\\]" $data "\ufff1" data

	regsub -all "\\\[" $data "\ufff2" data
	regsub -all "\\\]" $data "\ufff3" data

	regsub -all "\{" $data "\ufff4" data
	regsub -all "\}" $data "\ufff5" data

	regsub -all ":" $data " " data
	regsub -all "," $data " " data

	regsub -all "\ufff0" $data "\{\[\{- " data
	regsub -all "\ufff1" $data " -\}\]\}" data

	regsub -all "\ufff2" $data "\{" data
	regsub -all "\ufff3" $data "\}" data

	regsub -all "\ufff4" $data "\{- " data
	regsub -all "\ufff5" $data " -\}" data

	#puts ==================================================
	#puts >$data<
	set data [declose $data 1]
	#puts ==================================================
	#puts $data
	#puts ==================================================
    }
    if {[regexp {^\[(\{-.*-\})\]$} $data dummy data]} {
	# enumerated property list
	#puts $data
	#puts ======================================================================
	set i 0
	foreach part $data {
	    # remove the enclosing -
	    set part [declose $part 1]
	    #puts >>>$part<<<
	    json_to_map $part $mapname $prefix/$i
	    incr i
	}
    } else {
	#puts >>$data<<
	# simple property list
	foreach {prop value} $data {
	    if {[regexp {^\[(\{-.*-\})\]$} $value dummy value2]} {
		# enumerated property list
		json_to_map $value $mapname $prefix/$prop
	    } elseif {[regexp {^-(.*)-$} $value dummy value]} {
		# simple property list
		json_to_map $value $mapname $prefix/$prop
	    } else {
		#puts $prefix/$prop
		#puts "    $value"
		set map($prefix/$prop) $value
	    }
	}
    }
}



#===============================================================================
# https://core.tcl-lang.org/tcllib/file?name=modules/ncgi/ncgi.tcl&ci=tip
#===============================================================================

package provide ncgi 1.4.4

namespace eval ::ncgi {
    variable i
    variable c
    variable map

    for {set i 1} {$i <= 256} {incr i} {
	set c [format %c $i]
	if {![string match \[a-zA-Z0-9\] $c]} {
	    set map($c) %[format %.2X $i]
	}
    }

    # These are handled specially
    array set map {
	" " +   \n %0D%0A
    }
}

# ::ncgi::encode
#
#	This encodes data in www-url-encoded format.
#
# Arguments:
#	A string
#
# Results:
#	The encoded value
proc ::ncgi::encode {string} {
    variable map

    # 1 leave alphanumerics characters alone
    # 2 Convert every other character to an array lookup
    # 3 Escape constructs that are "special" to the tcl parser
    # 4 "subst" the result, doing all the array substitutions

    regsub -all -- \[^a-zA-Z0-9\] $string {$map(&)} string
    # This quotes cases like $map([) or $map($) => $map(\[) ...
    regsub -all -- {[][{})\\]\)} $string {\\&} string
    return [subst -nocommand $string]
}

catch {
    source [file dirname [info script]]/config.tcl
}

