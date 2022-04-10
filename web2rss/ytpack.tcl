# Copy all files from the yt/data directory with timestamp.
# (Dummy copies are created for the .m4a files)

source [file dirname [info script]]/rss-lib.tcl
set root [storage_root]/yt

if {![file exists $root/data]} {
    puts "$root/data doesn't exist. Nothing to pack"
    exit
}

set pwd [pwd]
cd $root/data
set files [glob *]
cd $pwd
file delete -force tmp
file mkdir tmp

foreach file $files {
    set src $root/data/$file
    set dst tmp/$file
    set t [file mtime $src]

    if {[regexp {tcl$} $file]} {
        file copy $src $dst
    } else {
        set fd [open $dst w+]
        close $fd
    }
    file mtime $dst $t
}
