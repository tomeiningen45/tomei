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

# This is for reading articles on cnbeta
#
package require ncgi

proc doit {} {
    global env
    set src http://m.cnbeta.com/view/482365.htm
    set src http://rss.cnbeta.com/rss

    if {[info exists env(REQUEST_URI)] && [regexp {ref=(.*)} $env(REQUEST_URI) dummy ref]} {
        set src http://m.cnbeta.com[ncgi::decode $ref]
    }

    set iphone 0
    catch {
        if {[regexp iPhone $env(HTTP_USER_AGENT)]} {
            set iphone 1
        }
    }

    set data [wget $src]
    set head "<html><head><META HTTP-EQUIV=\"content-type\" CONTENT=\"text/html; charset=utf-8\"></head><body>"
    set tail ""

    # (1) if article, rewrite the body
    if {"$src" == "http://rss.cnbeta.com/rss"} {
        regsub -all <title> $data \ufff0 data
        set out "<ul>"
        foreach part [split $data \ufff0] {
            if {[regexp {(.*)</title>} $part dummy title] &&
                [regexp {/([0-9]+).htm</link>} $part dummy link]} {
                append out "<li><a href=/cgi-bin/cnbetaview.cgi?ref=/view/$link.htm>$title</title>"
            }
        }
        set data $out
    } elseif {[regexp {^http://m.cnbeta.com/view/([0-9]+)} $src dummy page]} {
        regsub {.*<article id="[^>]*" class="article-holder">} $data "" data
        regsub {(<a href="[^>]*" class="artBt publishComment">更多评论</a>).*} $data \\1 data
        regsub {<!-- /content-->.*} $data "" data
        regsub {<section id="commentHolder".*} $data "" data

        set tail {
            <hr>
            <p id="thecmt">Loading comments</p>
            <script>
            state = 0;
            function doit() {
                if (window.XMLHttpRequest)
                {// code for IE7+, Firefox, Chrome, Opera, Safari
                    xmlhttp=new XMLHttpRequest();
                }
                else
                {// code for IE6, IE5
                    xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
                }
                xmlhttp.onreadystatechange = function() {
                    if (xmlhttp.readyState==4 && xmlhttp.status==200) {
                        document.getElementById("thecmt").innerHTML = xmlhttp.responseText;
                        state = -9999;
                    }
                }
                xmlhttp.open("GET", "/cgi-bin/cnbetacmt.cgi?ref=PAGE", true);
                xmlhttp.send();
            }

            function update () {
                if (state < 0) {
                    return;
                }
                state ++;
                window.setTimeout(update, 1000)
                document.getElementById("thecmt").innerHTML = "Loading comments: " + state;
            }

            document.getElementById("thecmt").innerHTML = "Loading comments: ...";
            doit();
            update()
            </script>
        }
        regsub PAGE $tail $page tail
        #<iframe width=100% src=\"/cgi-bin/cnbetacmt.cgi?ref=$page\"></iframe>"
    } elseif {[regexp "^http://m.cnbeta.com/comments_" $src]} {
        regsub {.*<span class="morComment">} $data "" data
        regsub {<!-- /content-->.*} $data "" data
    }

    regsub -all "href=\"/comments" $data "href=\"/cgi-bin/cnbetaview.cgi?ref=/comments" data
    regsub -all "href=\"/view" $data "href=\"/cgi-bin/cnbetaview.cgi?ref=/view" data

    regsub -all {<script[^>]*>[^<]*</script>} $data "" data
    regsub -all {<script } $data "<xxscript " data

    if {!$iphone} {
        set data "<table width=776 border=0 align=center cellspacing=0 cellpadding=5><tr><td>$data$tail</td></tr></table>"
    } else {
        set data "<font size=+4>$data$tail</font>"
        regsub -all "<img src=" $data "<img width=100% src=" data
    }

    return $head$data
}

source [file dirname [info script]]/lib.tcl
