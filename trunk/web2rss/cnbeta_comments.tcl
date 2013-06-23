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

        #set id 242117

        set input [wget http://www.cnbeta.com/comment.htm?&op=info&page=1&sid=$id]

        puts -nonewline " [expr [now] - $started] secs "

        set head {<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>  
}

        # translate to tcl code
        regsub -all : $input " " input
        regsub -all , $input " " input
        regsub -all \\\[ $input "\{" input
        regsub -all \\\] $input "\}" input

        set data "$head<div lang='zh' xml:lang='zh'>"
        set numcmt 0

        append data "<a href=http://www.cnbeta.com/articles/$id.htm>Original</a><p>"

        if {[catch {
            split_json [lindex $input 0] top
            split_json $top(result) results

            if {![info exists results(cmntstore)]} {
                append data "暂无评论<p>"
            } else {
                split_json $results(cmntstore) store

                foreach tid [array names store] {
                    split_json $store($tid) $tid
                    #parray $tid
                    #puts ----------------------------------------------------------------------
                }

                # ascending dates
                set results(cmntlist) [lreverse $results(cmntlist)]

                foreach {which name} {hot 热门评论 cmnt 所有评论} {
                    append data "<h3>$name</h3>\n"

                    set numcmt 0
                    foreach item $results(${which}list) {
                        split_json $item info
                        upvar 0 $info(tid) thecmt
                        append data "<font size=-1>$thecmt(name) \[$thecmt(score)\] @ $thecmt(date) $thecmt(host_name)</font><br>\n"
                        append data "$thecmt(comment)<br>\n"
                        append data "<p>\n"
                        incr numcmt
                    }
                    append data \n\n\n<hr>\n\n\n
                }
            }
        } err]} {
            puts $err
            puts $input
        }

        puts -nonewline "\[[format %3d $numcmt]\] "

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
        if {$count > 10} {
            #exit;
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
