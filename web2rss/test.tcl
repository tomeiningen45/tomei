# NOTES:
#
# output is in /opt/local/www/apache2/html/webrss

proc export {var} {
    global env
    set list [split $var =]
    set env([lindex $list 0]) [lindex $list 1]
}

 export DEBUG_ADAPTERS=
 export DEBUG_ARTICLE=
#export DEBUG_MAX_ARTICLES=
 export DEBUG_MAX_ARTICLES=1
#export DEBUG_MAX_DOWNLOADS=20

# Set the following to exit after the first site has finished writing to db
 export DEBUG_NO_LOOPS=1

#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} reuters"  (no more RSS feed from reuters)
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} bleacher"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} 6park_forum_mil"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} 6park"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} yahoohk"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} yahoojp_main"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} yahoojp_mag"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} yahoojp_sci"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} nhk"
 export DEBUG_ADAPTERS=gigazine


#parray env
#set env(DEBUG_ARTICLE) 
set env(DEBUG) 1


#proc variable {args} {
#    puts $args
#    puts [stacktrace]
#    exit
#}

proc stacktrace {} {
    set stack "Stack trace:\n"
    for {set i 1} {$i < [info level]} {incr i} {
        set lvl [info level -$i]
        set pname [lindex $lvl 0]
        append stack [string repeat " " $i]$pname
        foreach value [lrange $lvl 1 end] arg [info args $pname] {
            if {$value eq ""} {
                info default $pname $arg value
            }
            append stack " $arg='$value'"
        }
        append stack \n
    }
    return $stack
}

set fd [open c:/tmp/tmp.html w+]
fconfigure $fd -encoding utf-8
puts $fd {<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
}
puts $fd xxxx\u3053\u308cxxxx

close $fd
#exit

puts xxxx\u3053\u308cxxxx
#puts hello
source rss-nt.tcl
