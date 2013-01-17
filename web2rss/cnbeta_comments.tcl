#----------------------------------------------------------------------
# Standard prolog
#----------------------------------------------------------------------
set instdir [file dirname [info script]]
set datadir $instdir/data/cnbeta
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
        if {![regexp {([0-9]+)[.]htm} $link dummy id]} {
            continue
        }
        set started [now]
        puts -nonewline "Getting comments: $link "
        flush stdout

        set hot [wget http://www.cnbeta.com/comment/g_content/$id.html]
        set all [wget http://www.cnbeta.com/comment/normal/$id.html]
        puts -nonewline " [expr [now] - $started] secs "

        set head {<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>  
}

        set data "$head<div lang='zh' xml:lang='zh'><h3>热门评论</h3>$hot <hr> <h3>所有评论</h3>$all</div>"
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
        exec [ssh_prog] $env(WEB2RSSHOST) "rm -vf html/cnbeta_comments/*" 2>@ stderr >@ stdout
        puts "Deleting old files on remote host -- DONE"
    }

    catch {
        puts "Copying new files on remote host"
        exec [scp_prog] -r data/cnbeta_comments/ $env(WEB2RSSROOT)/ 2>@ stderr >@ stdout
        puts "Copying new files on remote DONE"

    }
} else {
    puts "No comments updated??"
}

puts "Elapsed [expr [now] - $started] secs"
