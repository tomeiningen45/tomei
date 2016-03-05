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


proc HttpdDate {seconds} {
    return [clock format $seconds -format {%a, %d %b %Y %T GMT} -gmt true]
}

proc put_header {fd hdr} {
    set hdr [string trim $hdr]
    regsub -all " *\n +" $hdr "\n" hdr
    regsub -all DATE $hdr [HttpdDate [clock seconds]] hdr
    puts $fd $hdr
    puts $fd ""
}

if {[catch {
    set data ""
    set index ""
    set cache /tmp/cnbeta.saved.rss
    if {![file exists $cache] || [clock seconds] - [file mtime $cache] > 180} {
        catch {exec wget -O $cache http://rss.cnbeta.com/rss 2> /dev/null}
    }
    set fd [open $cache]
    fconfigure $fd -encoding utf-8
    set src [read $fd]
    close $fd

    foreach line [split $src \n] {
        if {[regexp {<link>[^<]+/articles/([0-9]+).htm</link>} $line dummy n]} {
            set index $n
        }
        regsub {[\]][\]]></description>} $line "<p><p><a href=http://m.cnbeta.com/view/$index.htm>GO TO MOBILE SITE</a><p><p>\]\]></description>" line
        append data $line\n
    }

    #regsub -all www.cnbeta.com $data m.cnbeta.com data
    #regsub -all m.cnbeta.com/articles $data m.cnbeta.com/view data

    regsub {<title>[^<]+} $data "<title>cnBeta mobile" data
    regsub {<description>[^<]+} $data "<description>cnBeta mobile" data

    regsub {<rss version="2.0">} $data {<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:sy="http://purl.org/rss/1.0/modules/syndication/" xmlns:admin="http://webns.net/mvcb/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:georss="http://www.georss.org/georss" version="2.0">} data

    fconfigure stdout -encoding utf-8
    set hdr {
        Last-Modified: DATE
        Accept-Ranges: bytes
        Content-Length: LENGTH
        Connection: close
        Content-Type: application/xml
    }
    set tmp /tmp/cnbeta.cgi.out
    set tmpfd [open $tmp w+]
    fconfigure $tmpfd -encoding utf-8
    puts -nonewline $tmpfd $data
    close $tmpfd

    regsub LENGTH $hdr [file size $tmp] hdr
    put_header stdout $hdr
    puts -nonewline $data
    close stdout
}]} {
    puts "Content-Type: text/html\n"
    puts "<h1>CGI Error</h1>"
    puts "<pre>$errorInfo</pre>"
    puts "<h2>auto_path</h2>"
    puts "<pre>[join $auto_path \n]</pre>"
}

# http://blogs.yahoo.co.jp/tabasa7_blog/rss.xml


