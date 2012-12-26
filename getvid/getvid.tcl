# This is a handy GUI for getting loads of videos from the net
#
# Plan to support - tudou (via 92flv.com)
#                 - youtube (with the help of youtube-dl script)



# Get a playlist 
proc get_tudou_playlist {text} {
    set list ""
    regsub -all "<a title=\"" $text \uffff text
    foreach line [split $text \uffff] {
        if {[regexp "href=\"(http://www.tudou.com/listplay/\[^\"\]+)\"" $line dummy link] &&
            [regexp "^(\[^\"\]+)" $line dummy name]} {
            if {![info exists seen($link)]} {
                set seen($link) 1
                lappend list [list $link $name]
            }
        }
    }

    import_videos tudou $list
}

# list should be {url ?name?}
# if name cannot be determined, use ""
proc import_videos {site list} {
    global videos infos

    foreach item $list {
        set url [lindex $item 0]
        set name [lindex $item 1]

        if {[info exists videos($url)]} {
            puts "Video already imported: $url - '$name'"
            continue
        }
        
    }


}

proc import_toudou {} {
    global main

    wm withdraw $main(import_win)

    set t $main(import_text)
    set text [string trim [$t get 1.0 end]]
    get_tudou_playlist $text
}

proc start_import_ui {} {
    global main

    if {[info exists main(import_win)]} {
        wm deiconify $main(import_win)
        return
    }

    set w [toplevel .import]
    wm title $w "Import"

    set t [text $w.text]
    set f [frame $w.f]
    set b1 [button $f.toudou -text "Import Tudou" -command import_toudou]
    pack $b1 -side right
    pack $f -side bottom -fill x
    pack $t -side top -fill both -expand yes

    set main(import_win) $w
    set main(import_text) $t
}

proc make_main_ui {} {
    global main

    wm title . "GetVid"
    set f [frame .search_frame]
    set main(search) [entry $f.search -width 50]
    set b [button $f.b -text "Search"]
    pack $b -side right
    pack $main(search) -side left -expand yes -fill both
    pack $f -side top -fill x

    set main(list) [frame .mainlist -height 300]

    set f [frame .bottom]
    set i [button $f.import -text Import -command start_import_ui]
    set g [button $f.go -text Start]
    pack $i -side right
    pack $g -side left
    pack $f -side bottom -fill x
    pack $main(list) -side bottom -fill both -expand yes
}

make_main_ui

