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

