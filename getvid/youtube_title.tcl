set instdir [file dirname [info script]]
source $instdir/lib.tcl

set n 1
while {![eof stdin]} {
    set line [gets stdin]
    puts -nonewline "[format %3d $n] $line"
    incr n
    flush stdout
    set data [wget $line]
    if {[regexp {<title>([^<]+)</title>} $data dummy title]} {
        regsub { - YouTube$} $title "" title
        regsub -all {[_%]} $title " " title
        regsub -all { +} $title " " title
        regsub -all {&quot;} $title \" title
        regsub -all {&#39;} $title {'} title
        regsub -all / $title {.} title
        puts " $title"
    } else {
        puts ""
    }
    flush stdout
}