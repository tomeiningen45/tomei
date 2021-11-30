#!/bin/sh
# \
if [ -e /usr/local/opt/tcl-tk/bin/tclsh ]; then exec /usr/local/opt/tcl-tk/bin/tclsh "$0" ${1+"$@"} ; fi
# \
if [ -e /usr/bin/tclsh ]; then exec /usr/bin/tclsh "$0" ${1+"$@"} ; fi
# \
exec tclsh "$0" ${1+"$@"}

# Test
# http://localhost:9015/cgi-bin/im.cgi?a=http%3A%2F%2Fwww%2Epopo8%2Ecom%2Fpicts%2F201309%2F0901175733%5F85009%2Ejpg&b=http%3A%2F%2Fwww%2E6park%2Ecom%2Fnews%2Fmessages%2F43573%2Ehtml
#

open /tmp/im.cgi.log a

proc log {msg} {
    set fd [open /tmp/im.cgi.log a]
    puts $fd $img
    close $fd
}

if {[catch {
    package require ncgi
    package require html

    puts "Content-Type: image/jpeg"
    puts "Connection: Close"
    puts ""

    set url https://web.popo8.com/20211130/20211130094955_29089type_jpeg_size_318_200_end.jpeg
    set ref http://www.6park.com/news/messages/43573.html

    #foreach x "$url $ref" {
    #    puts stderr [ncgi::encode $x]
    #    puts stderr [ncgi::decode [ncgi::encode $x]]
    #}

    foreach "name value" [ncgi::nvlist] {
        if {"$name" == "a"} {
            set url $value
            regsub "\"\$" $url "" url
            regsub "\'\$" $url "" url
        } elseif {"$name" == "b"} {
            set ref $value
        }
    }

    foreach wget {/usr/bin/wget /usr/local/bin/wget /opt/local/bin/wget} {
        if {[file exists $wget]} {
            set fd [open "|$wget -O - --referer=$ref $url"]
            fconfigure $fd -translation binary -encoding binary
            fconfigure stdout -translation binary -encoding binary

            set n 0
            while {![eof $fd]} {
                set data [read $fd 4096]
                puts -nonewline stdout $data
                incr n [string length $data]
            }
            catch {close $fd}
            flush stdout

            log "[clock format [clock seconds] -format %y%m%d-%H%M%S] [format %8d $n]: $ref => $url"
            
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
