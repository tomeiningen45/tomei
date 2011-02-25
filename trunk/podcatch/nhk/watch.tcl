# Use this to watch the download status of a WMA file, because
# cvlc does not have very good status feedback.

set start [clock seconds]
set last -2

set file [lindex $argv 0]
if {$file == ""} {
    exit 1
}

while {[clock seconds] - $start < 7200} {
    if {[file exists $file]} {
        set size [file size $file]
        if {$size != $last} {
            set elapsed [expr [clock seconds] - $start]
            if {$elapsed < 1} {
                set elapsed 1
            }
            set kbps [expr $size / $elapsed / 1024.0]
            set time [format {%02d:%02d} [expr $elapsed / 60] [expr $elapsed % 60]]
            puts stderr "$file = [format "$time %6.1fKB (%3.1fKB/s)" [expr $size / 1024.0] $kbps]"
            set last $size
        }
    } 
    after [expr 10 * 1000]
}

