# Copy all files from the yt/data directory with timestamp.
# (Dummy copies are created for the .m4a files)

source [file dirname [info script]]/rss-lib.tcl
set root [storage_root]/yt

if {![file exists $root/data]} {
    puts "$root/data doesn't exist. Nothing to pack"
    exit
}

set pwd [pwd]
cd $root
set files [glob */*]
cd $pwd
file delete -force tmp/yt
file mkdir tmp/yt

foreach file [lsort $files] {
    set dir [file dirname $file]
    if {![file exists tmp/yt/$dir]} {
        file mkdir tmp/yt/$dir
    }
    set src $root/$file
    set dst tmp/yt/$file
    set t [file mtime $src]

    if {[regexp {tcl$} $file]} {
        file copy $src $dst
    } else {
        set fd [open $dst w+]
        close $fd
    }
    puts $dst
    file mtime $dst $t
}

cd tmp
exec tar cvf ../yt.tar yt 2>@ stdout >@ stdout

