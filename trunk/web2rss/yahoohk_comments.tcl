#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/hkyahoo
catch {
    file mkdir $datadir
}

source $instdir/rss.tcl

#----------------------------------------------------------------------
# Site specific scripts
#----------------------------------------------------------------------

set started [now]

proc update_comments {datadir links} {
    set dir ${datadir}_comments
    file mkdir $dir

    set all_started [now]

    set count 0
    set hasupdate 0

    foreach link $links {
        if {![regexp {[-]([0-9]+)(([-][-][0-9a-z]+)|)[.]html} $link dummy id]} {
            continue
        }
        set fname [getcachefile $link]
        if {![file exists $fname]} {
            continue;
        }
        set fd [open $fname]
        set data [read $fd]
        close $fd

        puts ----------------------------------------------------------------------
        puts $fname
        puts $link
        if {![regexp {<link rel="canonical" href="([^>]+)"/>} $data dummy canlink]} {
            continue
        }
        if {![regexp {data-contextid="([^>]+)">} $data dummy context]} {
            continue
        }

        append canlink ?ugccmtnav=v1%2Fcomments%2Fcontext%2F${context}%2Fcomments%3Fcount%3D100%26sortBy%3DhighestRated%26isNext%3Dtrue%26offset%3D0%26pageNumber%3D0

        puts $canlink

        set started [now]
        puts -nonewline "Getting comments: $link "
        flush stdout

        set data [wget $canlink]
        puts -nonewline " [expr [now] - $started] secs / [string length $data] wchars "

        if {![regsub {.*<div id="yom-comments" class="yom-mod yom-comments">} $data "" data] ||
            ![regsub {<div class="ugccmt-footer">.*} $data "" data]} {
            set data " -- error cannot not parse. Please see <a href=$canlink>HERE</a>"
        }

        regsub -all {<a id=.ugccmt-user-guid[^>]+>} $data "" data
        regsub -all {<img id=.ugccmt-user[^>]+>} $data "" data
        regsub -all {<div id=.ugccmt-comment[^>]+>} $data "<div>" data
        regsub -all {<span class="ugccmt-self-uri" style="display:none">[^<]+</span>} $data "" data
        regsub -all {class="[^>]+"} $data "" data
        regsub -all {id="[^>]+"} $data "" data
        regsub -all {<[!]--[^>]+>} $data "" data
        regsub -all "\n +" $data "" data
        regsub -all {<span[^>]*>} $data "" data
        regsub -all {</span[^>]*>} $data "" data
        regsub -all {<cite[^>]*>} $data "" data
        regsub -all {</cite[^>]*>} $data "" data
        regsub -all {<strong[^>]*>} $data "" data
        regsub -all {</strong[^>]*>} $data "" data
        regsub {<ul ><li>最熱門的</li><li><a >最新的</a></li><li><a >最舊的</a></li><li><a >回覆最多的</a></li></ul>} $data "" data
        regsub -all {<ul} $data {<xl} data
        regsub -all {<li} $data {<xi} data

        set head {<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>  
}

        set UPT "Updated [clock format [clock seconds]]<br>"

        set data "$head<div lang='zh' xml:lang='zh'>$UPT$data</div>"
        set updated($id) 1

        set cmtfile $dir/$id.html
        set olddata ""
        if {[file exists $cmtfile]} {
            set fd [open $cmtfile]
            fconfigure $fd -encoding utf-8
            set olddata [read $fd]
            close $fd
        }

        if {"$olddata" != "$data"} {
            set fd [open $cmtfile w+]
            fconfigure $fd -encoding utf-8
            puts -nonewline $fd $data
            close $fd
            puts UPDATED
            set hasupdate 1
        } else {
            puts ""
        }

        incr count
        if {$count > 5} {
            #break;
        }
    }

    foreach file [glob -nocomplain $dir/*.html] {
        if {![regexp {([0-9]+)[.]html} $file dummy id]} {
            continue
        }
        if {![info exists updated($id)]} {
            puts "Deleting old: $file"
            catch {
                file delete $file
            }
        }
    }

    puts "All comments updated in [expr [now] - $all_started] secs"
    return $hasupdate
}

if {[update_comments $datadir [read_links $datadir]]} {
    catch {
        puts "Deleting old files on remote host"
        exec [ssh_prog] $env(WEB2RSSHOST) "rm -vf html/hkyahoo_comments/*" 2>@ stderr >@ stdout
        puts "Deleting old files on remote host -- DONE"
    }

    catch {
        puts "Copying new files on remote host"
        exec [scp_prog] -r data/hkyahoo_comments/ $env(WEB2RSSROOT)/ 2>@ stderr >@ stdout
        puts "Copying new files on remote DONE"

    }
} else {
    puts "No comments updated??"
}

puts "Elapsed [expr [now] - $started] secs"
