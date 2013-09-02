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

# Test
# http://localhost:9015/cgi-bin/6pcmt.cgi?a=http%3A%2F%2Fwww.6park.com%2Fnews%2Fnewscom%2F43598.shtml
#

if {[catch {
    package require ncgi
    package require html

    puts "Content-Type: text/html; charset=gb2312"
    puts "Connection: Close"
    puts ""

    set url http%3A%2F%2Fwww.6park.com%2Fnews%2Fnewscom%2F43598.shtml

    foreach "name value" [ncgi::nvlist] {
        if {"$name" == "a"} {
            set url $value
        }
    }

    foreach wget {/usr/bin/wget /opt/local/bin/wget} {
        if {[file exists $wget]} {
            set fd [open "|$wget -O - $url"]
            fconfigure $fd -encoding gb2312
            fconfigure stdout -encoding gb2312

            set data [read $fd]
            catch {close $fd}

            regsub {<style[^>]*>.*</style>} $data "" data
            regsub -all {<a href=.http://t} $data <xx data
            regsub -all {<a href=.http://blog.e2bo} $data <xx data
            regsub -all {<font color=000000><u>..</u><font></a>} $data " " data
            regsub -all {<font color=000000><u>..</u><font></a>} $data " " data
            regsub -all {.<a onClick="[^>]+">..</a>.<B>.....</B>} $data " " data
            regsub -all {<B>..</B>:} $data "" data

            regsub -all {table width="800"} $data {table width="100%"} data
            regsub -all {table width=800} $data {table width="100%"} data
            regsub -all {<td([^>]*)>} $data {<td\1><font size=+1>} data
            regsub -all {</td>} $data {</font></td>} data


            puts $data

            
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
