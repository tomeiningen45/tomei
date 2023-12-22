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

#open /tmp/im.cgi.log a

proc log {msg} {
    set fd [open /tmp/im.cgi.log a+]
    puts $fd $img
    close $fd
}

if {[catch {
    package require ncgi
    package require html

    set test 0
    if {$test} {
	puts "Content-Type: text/plain"
    } else {
	puts "Content-Type: image/jpeg"
    }
    #puts "Connection: Close"

    # Example
    # http://a111.ddns.net:8080/hooks/im2/https%3A@@web.popo8.com@202112@16@14@e9a38ab63ctype_png_size_946_153_end.jpg%5Ehttps%3A@@www.6parknews.com@newspark@view.php%3Fapp%3Dnews%26act%3Dview%26nid%3D522691.jpg
    
    set url https://web.popo8.com/20211130/20211130094955_29089type_jpeg_size_318_200_end.jpeg
    set ref http://www.6park.com/news/messages/43573.html

    set req $env(QUERY_STRING)
    regsub -all @ $req / req

    if {[regexp {[\[\]\$\'\"\{\}\(\)]} $req]} {
	# prevent injection
	puts "Connection: Close"
	puts ""
	exit
    }
    
    set list [split $req ^]
    set url [lindex $list 0]
    set ref [lindex $list 1]
    regsub {[.]jpg$} $ref "" ref

    set pat {^((http)|(https))://}
    if {[llength $list] != 2 ||
	![regexp $pat $url] ||
	![regexp $pat $ref]} {
	puts "Connection: Close"
	puts ""
	exit
    }
    
    if {$test} {
	puts ""
	puts $url
	puts $ref
	exit 0
    }

    foreach wget {/usr/bin/wget /usr/local/bin/wget /opt/local/bin/wget} {
        if {[file exists $wget]} {
	    # First let see what the server response should be
	    if {[catch {
		set data [exec $wget -q -S --method=HEAD --referer=$ref $url 2>@ stdout | cat]
	    } err]} {
		if {"$env(REQUEST_METHOD)" == "HEAD"} {
		    puts "Content-Type: text/html\n"
		    puts "<h1>CGI Error</h1>"
		    puts "<pre>"
		    puts "Error:"
		    puts "ref: $ref"
		    puts "url: $url"
		    puts "cmd: wget -q -S --method=HEAD --referer=\$ref \$url"
		    puts "cmd: wget -q -S --method=HEAD --referer=$ref $url"
		    puts "err: $err"
		    puts "END</pre>"
		    exit 0
		} else {
		    set data "Content-Length: 0"
		}
	    }
	    if {[regexp {Content-Length: ([0-9]+)} $data dummy length]} {
	       #puts "Content-Length: $length"
		puts "Cache-control: public, max-age=2592000"
		puts "Last-Modified: Tue, 07 Dec 2021 19:50:32 GMT"
		puts "xx-orig: $url"
		puts "Connection: Close"
	    }
	    puts ""

	    if {"$env(REQUEST_METHOD)" == "HEAD"} {
		exit 0
	    }
	    
            set fd [open "|$wget -q -O - --referer=$ref $url"]
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

            #log "[clock format [clock seconds] -format %y%m%d-%H%M%S] [format %8d $n]: $ref => $url"
            
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
}
