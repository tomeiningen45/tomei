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


#----------------------------------------------------------------------
# This is for testing in the command-line
#
if {![info exists env(QUERY_STRING)]} {
    set env(QUERY_STRING) [lindex $argv 0]
}
if {![info exists env(SCRIPT_NAME)]} {
    set env(SCRIPT_NAME) [info script]
}
if {![info exists env(HTTP_HOST)]} {
    set env(HTTP_HOST) localhost:8015
}
#----------------------------------------------------------------------test


proc main {} {
    global env

    if {"$env(QUERY_STRING)" != ""} {
        if {[regexp {^name=(.*)} $env(QUERY_STRING) dummy name]} {
            if {[print_rss $name]} {
                exit 0
            }
        }
    }

    hint
}

proc print_rss {name} {
    global fetch_err errorInfo

    set data ""

    if {[catch {
        foreach num {50 25 10} {
            set url "http://gdata.youtube.com/feeds/api/users/$name/uploads?orderby=updated&v=1&max-results=50"
            set data [exec wget -q -O - $url 2> /dev/null]
            set xmldata [convert $name $data]
            if {"$xmldata" != ""} {

                return 1
            }
        }
    } err]} {
        set fetch_err $err--\n$errorInfo
    }
    return 0
}

proc tagsplit {text tag} {
    regsub -all $tag $text \uffff text
    return [split $text \uffff]
}

proc convert {chan_name data} {
    global env
    set root http://$env(HTTP_HOST)

    set total 0
    foreach item [tagsplit $data {<title[^>]*>}] {
        incr idx
        if {$idx <= 2} {
            continue
        }
        regsub -all "&" $item "\\\\&" item
        if {[regexp {^([^<]+)</title>} $item dummy title]} {
            set description ""
            set video ""
            if {![regexp {<media:description[^>]*>([^<]+)</media:description>} $item dummy description] ||
                ![regexp {<link[^>]*href='http://www.youtube.com/watch[?]v=([A-Za-z0-9_+-]+)} $item dummy watch]} {
                continue
            }

            set i $total; incr total

            set wat($i) $watch
            set tit($i) [string trim $title]
            set des($i) [string trim $description]
            set url($i) http://feedproxy.google.com/~r/cnet/cartechvideohd/~3/9S-mzF1R84Y/cnet_2012-05-30-180237.2500.mp4
            set url($i) $root/cgi-bin/movie.cgi?name=$watch

            set sum($i) $des($i)
            if {[string first "<!\[CDATA\[" $sum($i)] != 0} {
                set sum($i) "<!\[CDATA\[$sum($i)\]\]"
            }
            set dat($i) "Wed, 30 May 2012 03:01:36 PDT"
        }
    }

    if {$total <= 0} {
        return "";
    }

    puts "Content-Type: application/xhtml+xml"
    puts "Encoding: UTF-8"
    puts ""

    global feed_template

    regsub -all CHANNEL $feed_template $chan_name feed_template
    puts $feed_template

    puts "<title>$chan_name</title>"

    for {set i 0} {$i < $total} {incr i} {
        global item_template
        set t $item_template

        set t {
            <item>
            <title>TITLE</title>
            <link rel='alternate' type='text/html' href='LINK_URL'></link>
            <author>cartech@cnet.com (CNETTV.com)</author>
            <description>DESCRIPTION</description>
            <itunes:subtitle>SUBTITLE</itunes:subtitle>
            <itunes:summary><![CDATA[A brand new Infiniti SUV that goes after X5 and Cayenne, but with less.]]></itunes:summary>
            <itunes:explicit>no</itunes:explicit>
            <itunes:author>AUTHOR</itunes:author>
            <itunes:duration>386</itunes:duration>
            <enclosure url="MEDIA_URL" length="0" type="video/mp4" />
                            
            <category>Technology</category>
                                
            <pubDate>DATE</pubDate>
            <media:content url="MEDIA_URL" type="video/mp4" />
            </item>
        }

        regsub -all TITLE       $t $tit($i)    t
        regsub -all LINK_URL    $t "http://www.youtube.com/watch?v=$wat($i)" t
        regsub -all MEDIA_URL   $t $url($i)    t
        regsub -all DESCRIPTION $t $des($i)    t
        regsub -all DATE        $t $dat($i)    t
        regsub -all AUTHOR      $t $chan_name  t
        regsub -all SUBTITLE    $t $sum($i)    t
        regsub -all SUMMARY     $t $sum($i)    t

        puts $t
        if {$i > 3 && false} {
            break
        }
    }

    puts "</channel></rss>"
    exit
}

proc hint {} {
    global env fetch_err

    puts "Content-Type: text/html"
    puts ""
    puts <ul>

    foreach {name title} {
        CARandDRIVER "Car and Driver"
    } {
        puts "<li><a href=$env(SCRIPT_NAME)?name=$name>$title</li>"
    }
    puts "</ul>"
    if {[info exists fetch_err]} {
        puts "<pre>ERROR:\n$fetch_err</pre>"
    }
}

set feed_template {<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" media="screen" href="/~d/styles/rss2enclosuresfull.xsl"?><?xml-stylesheet type="text/css" media="screen" href="http://feeds.feedburner.com/~d/styles/itemcontent.css"?><rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/" xmlns:feedburner="http://rssnamespace.org/feedburner/ext/1.0" version="2.0">

    

    
  <channel>
      
      <title>Youtube: CHANNEL</title>
<itunes:author>CHANNEL</itunes:author>
      <link>http://cnettv.cnet.com/</link>
      <copyright></copyright>
      <description></description>
      
              <managingEditor>feedback-cnettv@cnet.com (CNETTV)</managingEditor>
          
      <webMaster>CHANNEL</webMaster>
      <language>en-us</language>
      <itunes:explicit>no</itunes:explicit>
      <itunes:subtitle></itunes:subtitle>
      <itunes:summary></itunes:summary>

              <category>Technology</category>
              
              
          
      <lastBuildDate>Tue, 05 Jun 2012 12:33:34 PDT</lastBuildDate>
      <pubDate>Tue, 05 Jun 2012 12:33:34 PDT</pubDate>
      <docs>http://blogs.law.harvard.edu/tech/rss</docs>
      

                        
                        <feedburner:info uri="cnet/cartechvideohd" /><atom10:link xmlns:atom10="http://www.w3.org/2005/Atom" rel="hub" href="http://pubsubhubbub.appspot.com/" /><media:copyright>2009 CNET.com</media:copyright><media:thumbnail url="http://www.cnet.com/i/pod/images/podcastsHD_cartech_600x600.jpg" /><media:keywords>car,talk,automotive,audiovox,hybrid,bose,GPS,MP3,gadget,XM,satellite,radio,CD,media</media:keywords><media:category scheme="http://www.itunes.com/dtds/podcast-1.0.dtd">Games &amp; Hobbies/Automotive</media:category><media:category scheme="http://www.itunes.com/dtds/podcast-1.0.dtd">Technology</media:category><itunes:owner><itunes:email>cartech@cnet.com</itunes:email><itunes:name>CNETTV.com</itunes:name></itunes:owner><itunes:keywords>car,talk,automotive,audiovox,hybrid,bose,GPS,MP3,gadget,XM,satellite,radio,CD,media</itunes:keywords><itunes:category text="Games &amp; Hobbies"><itunes:category text="Automotive" /></itunes:category><itunes:category text="Technology" /><atom10:link xmlns:atom10="http://www.w3.org/2005/Atom" rel="self" type="application/rss+xml" href="http://cartechhdpodcast.cnettv.com/" /><feedburner:feedFlare href="http://add.my.yahoo.com/rss?url=http%3A%2F%2Fcartechhdpodcast.cnettv.com%2F" src="http://us.i1.yimg.com/us.yimg.com/i/us/my/addtomyyahoo4.gif">Subscribe with My Yahoo!</feedburner:feedFlare><feedburner:feedFlare href="http://www.newsgator.com/ngs/subscriber/subext.aspx?url=http%3A%2F%2Fcartechhdpodcast.cnettv.com%2F" src="http://www.newsgator.com/images/ngsub1.gif">Subscribe with NewsGator</feedburner:feedFlare><feedburner:feedFlare href="http://www.bloglines.com/sub/http://cartechhdpodcast.cnettv.com/" src="http://www.bloglines.com/images/sub_modern11.gif">Subscribe with Bloglines</feedburner:feedFlare><feedburner:feedFlare href="http://www.netvibes.com/subscribe.php?url=http%3A%2F%2Fcartechhdpodcast.cnettv.com%2F" src="http://www.netvibes.com/img/add2netvibes.gif">Subscribe with Netvibes</feedburner:feedFlare><feedburner:feedFlare href="http://fusion.google.com/add?feedurl=http%3A%2F%2Fcartechhdpodcast.cnettv.com%2F" src="http://buttons.googlesyndication.com/fusion/add.gif">Subscribe with Google</feedburner:feedFlare><feedburner:feedFlare href="http://www.pageflakes.com/subscribe.aspx?url=http%3A%2F%2Fcartechhdpodcast.cnettv.com%2F" src="http://www.pageflakes.com/ImageFile.ashx?instanceId=Static_4&amp;fileName=ATP_blu_91x17.gif">Subscribe with Pageflakes</feedburner:feedFlare><feedburner:feedFlare href="http://odeo.com/listen/subscribe?feed=http%3A%2F%2Fcartechhdpodcast.cnettv.com%2F" src="http://odeo.com/img/badge-channel-black.gif">Subscribe with ODEO</feedburner:feedFlare><feedburner:feedFlare href="http://www.podnova.com/add.srf?url=http%3A%2F%2Fcartechhdpodcast.cnettv.com%2F" src="http://www.podnova.com/img_chicklet_podnova.gif">Subscribe with Podnova</feedburner:feedFlare>
}

set item_template {
    <item>
    <title>TITLE</title>
    <Link>MEDIA_URL/link>
    <author>AUTHOR</author>
    <description>DESCRIPTION</description>
    <itunes:subtitle>SUBTITLE</itunes:subtitle>
    <itunes:summary>SUMMARY></itunes:summary>
    <itunes:explicit>no</itunes:explicit>
    <itunes:author>AUTHOR</itunes:author>
    <pubDate>DATE</pubDate>
    <media:content url="MEDIA_URL" type="video/mp4" />
    </item>
}

main
exit 0
