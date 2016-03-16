# How to use --
#
# proc doit () {
#     return ....
# }
#
# source [file dirname [info script]]/lib.tcl

proc wget {url {encoding utf-8}} {
    global env

    set data ""
    set tmpfile /tmp/wget-rss-[pid]

    catch {
        file delete $tmpfile
        exec wget --no-check-certificate --timeout=10 --tries=1 -q -O $tmpfile $url 2> /dev/null > /dev/null

        if {"$encoding" == "gb2312"} {
            set fd [open "| cat $tmpfile | iconv -f gbk -t utf-8" r]
            set encoding utf-8
        } else {
            set fd [open $tmpfile]
        }
        fconfigure $fd -encoding $encoding
        set data [read $fd]
        regsub {CONTENT="text/html; charset=[^>]*">} $data {CONTENT="text/html; $encoding">} data
        close $fd
        file delete $tmpfile
    } err

    return $err$data
}

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
    set data [doit]

    fconfigure stdout -encoding utf-8
    if {[info exists isfeed]} {
        set hdr {
            Last-Modified: DATE
            Accept-Ranges: bytes
            Content-Length: LENGTH
            Connection: close
            Content-Type: application/xml
        }
    } else {
        set hdr {
            Last-Modified: DATE
            Accept-Ranges: bytes
            Content-Length: LENGTH
            Connection: close
            Content-Type: text/html
        }
    }
    set tmp /tmp/cgi-[pid].out
    file delete -force $tmp

    set tmpfd [open $tmp w+]
    fconfigure $tmpfd -encoding utf-8
    puts -nonewline $tmpfd $data
    close $tmpfd

    regsub LENGTH $hdr [file size $tmp] hdr
    put_header stdout $hdr
    puts -nonewline $data
    close stdout
    file delete -force $tmp
}]} {
    puts "Content-Type: text/html\n"
    puts "<h1>CGI Error</h1>"
    puts "<pre>$errorInfo</pre>"
    puts "<h2>auto_path</h2>"
    puts "<pre>[join $auto_path \n]</pre>"
}

# http://blogs.yahoo.co.jp/tabasa7_blog/rss.xml


