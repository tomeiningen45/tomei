#!/bin/sh
# \
if [ -e /usr/bin/tclsh ]; then exec /usr/bin/tclsh "$0" ${1+"$@"} ; fi
# \
if [ -e /usr/local/bin/tclsh8.4 ]; then exec /usr/local/bin/tclsh8.4 "$0" ${1+"$@"} ; fi
# \
if [ -e /usr/local/bin/tclsh8.3 ]; then exec /usr/local/bin/tclsh8.3 "$0" ${1+"$@"} ; fi
# \
if [ -e /usr/bin/tclsh8.4 ]; then exec /usr/bin/tclsh8.4 "$0" ${1+"$@"} ; fi
# \
exec tclsh "$0" ${1+"$@"}

proc extract_and_junk_one_block {dataName begin end} {
    upvar $dataName data

    #puts $data
    #puts $begin-$end

    regsub -all $begin $data \uFFFE data
    regsub -all $end   $data \uFFFF data
    set pat {\uFFFE([^\uFFFF]*)\uFFFF}

    set result {}
    if {[regexp $pat $data dummy result]} {
        regsub $pat $data "" data
    }

    regsub -all \uFFFE $data $begin data
    regsub -all \uFFFF $data $end   data

    return $result
}


# Test
# http://localhost:9015/cgi-bin/hky.cgi?a=http%3A%2F%2Fhk.news.yahoo.com%2F%E4%B8%83%E5%A7%8A%E5%A6%B9%E9%81%936%E5%B0%8F%E6%99%822%E5%A5%B3%E8%87%AA%E6%AE%BA-224524333.html
#

if {[catch {
    package require ncgi
    package require html

    puts "Content-Type: text/html; charset=UTF-8"
    puts "Connection: Close"
    puts ""

    set url http%3A%2F%2Fhk.news.yahoo.com%2F%E4%B8%83%E5%A7%8A%E5%A6%B9%E9%81%936%E5%B0%8F%E6%99%822%E5%A5%B3%E8%87%AA%E6%AE%BA-224524333.html

    foreach "name value" [ncgi::nvlist] {
        if {"$name" == "a"} {
            set url $value
        }
    }

    puts "<a href=$url>Orig</a><hr>"
    foreach wget {/usr/bin/wget /opt/local/bin/wget} {
        if {[file exists $wget]} {
            fconfigure stdout -encoding utf-8

            set fd [open "|$wget -O - $url"]
            fconfigure $fd -encoding utf-8
            set data [read $fd]
            catch {close $fd}

            if {![regexp "\"content_id\":\"(\[^\"\]+)\"" $data dummy context]} {
                error
            }

            set url1 http://hk.news.yahoo.com/_xhr/ugccomments/?method=get_list&context_id=${context}&ugccmtnav=v1%2Fcomments%2Fcontext%2F${context}%2Fcomments%3Fcount%3D100%26sortBy%3DhighestRated%26isNext%3Dtrue%26offset%3D0%26pageNumber%3D1&mode=list
            puts stderr $url1

            set fd [open "|$wget -O - $url1"]
            fconfigure $fd -encoding utf-8
            set data [read $fd]
            catch {close $fd}

            set prefix ""
            set n 1
            while {1} {
                set name [extract_and_junk_one_block data <strong> {<./strong>}]
                set comm [extract_and_junk_one_block data {commenttext..>} {<./blockquote>}]
                catch {set name [subst $name]}
                catch {set comm [subst $comm]}
                if {"$name" == "" && "$comm" == ""} {
                    break
                }
                puts $prefix
                puts "\[$n\] $name<br>"
                puts {<div STYLE="margin-left:50px">}
                puts $comm

                set prefix <hr>
                puts "</div>"
                incr n
            }

            flush stdout

            puts stderr "[clock format [clock seconds] -format %y%m%d-%H%M%S]: $url"
            flush stderr
            
            exit
        }
    }

    #html::head Hello
    #flush stdout

    exit 0
}]} {
    puts "Content-Type: text/html\n"
    puts "<h1>CGI Error</h1>"
    puts "<pre>$errorInfo</pre>"
    puts "<h2>auto_path</h2>"
    puts "<pre>[join $auto_path \n]</pre>"
}
