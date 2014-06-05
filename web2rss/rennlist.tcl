#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/rennlist
catch {
    file mkdir $datadir
}

source $instdir/rss.tcl

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------

proc update {} {
    global datadir env

    set data [wget http://forums.rennlist.com/rennforums/external.php?type=RSS2&forumids=218]

    set out ""
    set prefix ""
    foreach item [makelist $data <title> 0] {
        append out $prefix

        if {[regexp {(http://forums.rennlist.com/rennforums/vehicle-marketplace/([^<]*))</link>} $item dummy link name]} {
            puts -nonewline $link
            set data [getfile $link $name]
            if {[regexp {<strong>Price[^<]*</strong> .([^<]+)<br />} $data dummy price]} {
                set mileage ""
                if {[regexp {<strong>Mileage[^<]*</strong>([^<]+)<} $data dummy mileage]} {
                    catch {
                        set mileage " @ [expr [string trim $mileage] / 1000]K mi"
                    }
                }
                puts -nonewline ": $price$mileage"
                regsub </title> $item " - \$$price$mileage</title>" item
                regsub -all {<div style="padding:[0-9]+px">} $item "" item
                regsub -all {<fieldset class="fieldset">} $item "" item
                regsub -all {<legend>Attached Images</legend>} $item "" item
            }
            puts ""
        }
        append out $item
        set prefix <title>
    }

    set fd [open $datadir.xml w+]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd $out
    close $fd
}

update
