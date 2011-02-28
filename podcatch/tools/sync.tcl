#! /usr/bin/tclsh

rename exec exec.orig
proc exec {args} {
    puts "exec $args"
    return [eval exec.orig $args]
}

catch {
    unset env(SSH_AUTH_SOCK)
}

set user $env(NHKEXPORT)
set changed 0

proc delfiles {} {
    global user dir maxfiles changed

    set files [lsort -decreasing [exec ssh $user ls -t $dir]]
    regsub list.txt $files "" files
    #puts ===$files===
    set todel [lrange $files $maxfiles end]

    if {[llength $todel] > 0} {
        puts "deleting in $dir == $todel"
        exec ssh $user "cd $dir; rm -f $todel"
        set changed 1
    } else {
        puts "no files to delete"
    }
}

proc pushfiles {files} {
    global user dir maxfiles changed

    set files [lsort -decreasing [eval exec ls -t $files]]
    set topush [lrange $files 0 [expr $maxfiles - 1]]

    set remotefiles [exec ssh $user ls -t $dir]
    foreach r $remotefiles {
        set has($r) 1
    }

    foreach f $topush {
        set t [file tail $f]
        if {![info exists has($t)]} {
            puts "NEW: $f"
            exec scp $f $user:$dir 2>@ stderr >@ stdout
            set changed 1
        }
    }
}    

proc indexfiles {} {
    global user dir maxfiles

    exec ssh $user "cd $dir; ls -t *.mp3 > list.txt"
}

set dir [lindex $argv 0]
set maxfiles [lindex $argv 1]

delfiles 
pushfiles [lrange $argv 2 end]
delfiles

if {$changed} {
    indexfiles
} else {
    puts "No need to update list.txt -- no changes pushed to server"
}



