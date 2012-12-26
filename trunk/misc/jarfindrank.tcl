# Find the rank in the JAR file entry list

# This is the output of "jar tf rt.jar"
set jar_tf_out [lindex $argv 0]

# This is the output of "java -verbose ...." for running a Java
# app (like eclipse) to print out all loaded classes
set java_verbose_out [lindex $argv 1]

set total_entry 0
set fd [open $jar_tf_out]
while {![eof $fd]} {
    set line [string trim [gets $fd]]
    incr total_entry
    if {[regsub {[.]class$} $line "" line]} {
        set tab($line) $total_entry
    }
}
close $fd

set total_loaded 0
set total_ranked 0
set fd [open $java_verbose_out]
while {![eof $fd]} {
    set line [string trim [gets $fd]]
    if {[regexp {Loaded ([^ ]+) from} $line dummy class]} {
        incr total_loaded
        regsub -all {[.]} $class / class
        #puts $class
        if {[info exists tab($class)]} {
            set rank [expr $total_entry - $tab($class)]
            set r($rank) $class
            incr total_ranked
        }
    }
}
close $fd

set n $total_ranked
foreach rank [lrange [lsort -integer -decreasing [array names r]] 0 end] {
    set perc  [expr $rank / $total_entry.0 * 100]
    set perc2 [expr $n    / $total_ranked.0 * 100]
    puts [format {[%6.2f] %6d of %6d %5.2f%% %s} $perc2 $rank $total_entry $perc $r($rank)]
    incr n -1
}
