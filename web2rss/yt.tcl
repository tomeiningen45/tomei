set config(max-download) 10
set config(max-storage)  20
set config(max-retry)    3

source [file dirname [info script]]/rss-lib.tcl

set sources [file dirname [info script]]/ytsources.tcl
set ytdl    [file dirname [info script]]/youtube-dl
source $sources

puts "storage_root = [storage_root]"
# Get the first $limit ids in this playlist. The ids are
# sorted in reversed order. E.g., if limit is 4 and the
# list has videos {A B C} D, the returned list is {C B A}
#
# The videos will be downloaded in the order of C B A, which
# means A will have the newest modification date.
#
# The RSS list will be sorted with newsest on top. E.g.: A B C
proc get_ids {url limit} {
    global config thumbs

    set data [exec wget --no-check-certificate --timeout=10 --tries=1 -q -O - $url 2> /dev/null]
    set list {}

    regsub -all {\"videoId\":\"} $data \uffff data
    foreach line [split $data \uffff] {
        if {[regexp {^([0-9a-zA-Z_-]+)\"} $line dummy id]} {
            if {![info exists seen($id)]} {
                set seen($id) 1
                lappend list $id

                if {[regexp {"thumbnail":\{"thumbnails":\[\{"url":\"([^\"]+)} $line dummy t]} {
                    set thumbs($id) $t
                }
            }
        }
    }

    return [lreverse [lrange $list 0 [expr $limit - 1]]]
}


proc main {} {
    global ytsrc ytdl config thumbs
    set root [storage_root]/yt

    if {![file exists $root]} {
        puts "creating directory $root"
        file mkdir $root
    }
    if {![file exists $root/data]} {
        puts "creating directory $root/data"
        file mkdir $root/data
    }

    # Look for stuff to download (in reversed order in list)
    set worklist {}
    set maxlen 0
    foreach site [array names ytsrc] {
        set download_limit [lindex $ytsrc($site) 0]
        set storage_limit  [lindex $ytsrc($site) 1]
        set name           [lindex $ytsrc($site) 2]
        set url            [lindex $ytsrc($site) 3]

        puts "Getting list $site-$url"
        set ids($site) [get_ids $url $download_limit]
        set len [llength $ids($site)]
        if {$maxlen < $len} {
            set maxlen $len
        }
    }

    # Spread the ids to check for download
    for {set i 0} {$i < $maxlen} {incr i} {
        foreach site [array names ytsrc] {
            set id [lindex $ids($site) $i]
            if {"$id" != ""} {
                puts "[format %3d $i] $site-$id"
                lappend worklist [list $site $id]
            }
        }
    }


    # Download each video, oldest first
    foreach item $worklist {
        set site [lindex $item 0]
        set id   [lindex $item 1]

        set sitedir $root/$site
        if {![file exists $sitedir]} {
            puts "creating directory $sitedir"
            file mkdir $sitedir
        }

        set timestamp    $sitedir/$id.tcl
        set metadata     $root/data/$id.tcl
        set url          "https://www.youtube.com/watch?v=$id"
        set filenamespec "$root/data/%(id)s.%(ext)s"
        set update 0

        # Make the discovery timestamp for this $site
        if {![file exists $timestamp]} {
            set update 1
            set fd [open $timestamp w+]
            set ms [clock milliseconds]
            puts "Creating timestamp $timestamp @ $ms"
            puts $fd "set ts($id) $ms"
            catch {
                puts $fd "set thumb($id) [list $thumbs($id)]"
            }
            close $fd
            # Make sure all timestamps are separated by at least 1 millisecond
            after 1
        }

        # Download the audio data
        catch {unset metainfo($id)}
        set retrycount 0
        set succeeded 0

        if {[file exists $metadata]} {
            # Format
            # metainfo($id) = [list $retrycount $filename $title $pubdate $description $succeeded]
            if {[catch {
                source $metadata
                set succeeded   [expr 0 + [lindex $metainfo($id) 5]]
                set retrycount  [lindex $metainfo($id) 0]
                if {$succeeded == 0} {
                    puts "Should we retry $id after retrycount == $retrycount?"
                }
            } error]} {
                puts "Invalid metainfo in $metadata"
                puts $error
                set fd [open $metadata r]
                puts "===== file content of $metadata"
                puts [string trim [read $fd]]
                puts "====="
                close $fd
                file delete $metadata
                set succeeded 0
            }
        }

        if {!$succeeded} {
            set filename unknown

            set succeeded 0
            set title ""
            set pubdate [clock milliseconds]
            set description ""

            if {$retrycount < $config(max-retry)} {
                puts "Downloading audio data from $url"
                if {[catch {
                    # Read the descriptions, etc
                    set data [exec wget --no-check-certificate --timeout=10 --tries=1 -q -O - $url 2> /dev/null]
                    puts [string len $data]
                    set pat {"description":\{"simpleText":\"([^\"]+)}
                    puts $pat
                    regexp $pat $data dummy description
                    regexp {"title":\{"simpleText":\"([^\"]+)} $data dummy title
                    puts $title
                    puts $description                                             
                    set filename [exec $ytdl --get-filename --no-mtime -o $filenamespec -x $url]
                    puts "filename = $filename"
                    if {![file exists $filename]} {
                        exec $ytdl --no-mtime -o $filenamespec -x $url 2>@ stdout >@ stdout
                    }
                    set succeeded [file exists $filename]
                    if {!$succeeded} {
                        incr retrycount
                    }
                    puts "Succeeded"
                } errInfo]} {
                    puts "*** Failed to download audio data"
                    puts $errInfo
                }
                puts "Writing $metadata"
                set fd [open $metadata w+]
                puts $fd "set     metainfo($id) $retrycount"
                puts $fd "lappend metainfo($id) $filename"
                puts $fd "lappend metainfo($id) [list $title]"
                puts $fd "lappend metainfo($id) [list $pubdate]"
                puts $fd "lappend metainfo($id) [list $description]"
                puts $fd "lappend metainfo($id) [list $succeeded]"
                close $fd
                puts "$filename (Succeeded = $succeeded)"
                if {$succeeded} {
                    set update 1
                }
            } else {
                puts "No: retrycount ($retrycount) is over limit ($config(max-retry))"
                puts "To retry this file even more:"
                puts "      rm $metadata"
            }
        }

        if {[file exists $metadata] && $update || 1} {
            update_xml $site
        }
    }
}

proc sort_by_newest_timestamp {a b} {
    global ts
    return [expr $ts($a) - $ts($b)]
}

proc update_xml {site} {
    global ts ytsrc ytcfg thumbs
    set webroot $ytcfg(webroot)

    catch {unset ts}
    set xml [storage_root]/$site.xml
    set sitedir [storage_root]/yt/$site
    if {![file exists $sitedir]} {
        return
    }
    foreach file [glob $sitedir/*.tcl] {
        catch {source $file}
    }


    set fd [open $xml w+]
    set out {<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"
	xmlns:content="http://purl.org/rss/1.0/modules/content/"
	xmlns:wfw="http://wellformedweb.org/CommentAPI/"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:atom="http://www.w3.org/2005/Atom"
	xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
	xmlns:slash="http://purl.org/rss/1.0/modules/slash/"
	xmlns:podcast="https://github.com/Podcastindex-org/podcast-namespace/blob/main/docs/1.0.md"
	xmlns:rawvoice="http://www.rawvoice.com/rawvoiceRssModule/"
	xmlns:googleplay="http://www.google.com/schemas/play-podcasts/1.0">

        <channel>
	<title>DESC</title>
	<link>URL</link>
	<description>DESC</description>
	<lastBuildDate>DATE</lastBuildDate>
	<language>LANG</language>
	<sy:updatePeriod>hourly</sy:updatePeriod>
	<sy:updateFrequency>1</sy:updateFrequency>

        <image>
	<url>WEBROOT/podcast.jpg</url>
        </image> 
    }
        
    set date [clock_format [clock seconds]]
    regsub -all DATE        $out $date out
    regsub -all LANG        $out jp out
    regsub -all DESC        $out [lindex $ytsrc($site) 2] out
    regsub -all URL         $out [lindex $ytsrc($site) 3] out
    regsub -all WEBROOT     $out $webroot out
 

    puts $fd $out

    set list [lsort -command sort_by_newest_timestamp [array names ts]]
    foreach id $list {
        puts $ts($id)
        set metadata [storage_root]/yt/data/$id.tcl
        if {[file exists $metadata] && [catch {
            catch {unset metainfo($id)}
            source $metadata
            set info $metainfo($id)
            set filename    [lindex $info 1]
            set title       [lindex $info 2]
            set pubdate     [lindex $info 3]
            set description [lindex $info 4]
            set succeeded   [lindex $info 5]

            set length [file size $filename]
            regsub "^.*/webrss/" $filename "" filename
            regsub -all "\\\\n" $description "<br>\n" description

            catch {unset thumb}

            catch {
                set thumb $thumbs($id)
                set description "$description <p> <img src=\"$thumb\"> "
            }

            if {0 + $succeeded >= 0} {
                puts $fd "<item><title>$title</title>"
                puts $fd "<link>https://www.youtube.com/watch?v=$id</link>"
		puts $fd "<dc:creator><!\[CDATA\[siran\]\]></dc:creator>"
		puts $fd "<pubDate>[clock_format $pubdate]</pubDate>"
                puts $fd "<category><!\[CDATA\[ラジオ\]\]></category>"
                puts $fd "<description><!\[CDATA\[$description\]\]></description>"
                puts $fd "<enclosure url=\"$webroot/$filename\" length=\"$length\" type=\"audio/mpeg\" />"
                if {[info exists thumb]} {
                    #puts $fd "<itunes:image href=\"$thumb\" />"
                    #puts $fd "<media:thumbnail url=\"$thumb\" />"
                    #puts $fd "<media:content url=\"$thumb\" type=\"image/jpeg\" />"
                }

                puts $fd "</item>"
            }

            puts $filename-$succeeded-$title
        } errInfo]} {
            puts $errInfo
        }
    }

    puts $fd {</channel></rss>}
    close $fd

    exit
}


main


# ./youtube-dl --no-mtime -o '%(id)s.%(ext)s' -x https://www.youtube.com/watch?v=0v8VRhSZ7wc 
