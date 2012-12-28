#! /usr/bin/wish

# This is a simple script that watches the X11 selection
# buffer for youtube URLs (browser right-click -> copy URL)
# It prints all such URLs into stdout
#
#
# Usage:
#
# wish youtube_watch_url.tcl | tclsh youtube_title.tcl > mylist.list
listbox .l -width 50 -font {fixed 8}
pack .l -expand yes -fill both

set n 1
while 1 {
    after 300
    catch {
        set sel [selection get]
        if {[regexp {^http://www.youtube.com/watch.*} $sel] &&
            ![regexp { } $sel]} {
            regsub {[&]list=.*} $sel "" sel
            if {![info exists seen($sel)]} {
                set seen($sel) 1
                puts stdout $sel
                flush stdout
                .l insert 0 "[format %3d $n] $sel"
                update
                incr n
            }
        }
    }
}
