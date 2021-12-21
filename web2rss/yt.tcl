set config(max-download) 10
set config(max-storage)  20
set config(max-retry)    3

source [file dirname [info script]]/rss-lib.tcl
set env(CLASSPATH) [file dirname [info script]]

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
proc get_ids {site url limit {showname 0}} {
    global config thumbs yt

    set data [exec wget --no-check-certificate --timeout=10 --tries=1 -q -O - $url 2> /dev/null | java FilterEmoji]
    set list {}

    if {[is_watchlist $site]} {
        set channels [get_channels_from_watchlist $data]
        set n 0
        foreach channel $channels {
            incr n
            puts "Watchlist [format %3d $n]: get top video from $channel"
            set videos [get_ids {} $channel 1 1]
            if {[llength $videos] == 0} {
                puts "               No videos??"
            } else {
                set list [concat $list $videos]
            }
        }
        return $list
    }

    if {$showname && [regexp {"channelMetadataRenderer":\{"title":"([^\"]+)"} $data dummy title]} {
        puts "               $title"
    }

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



proc is_watchlist {site} {
    global ytsrc
    if {![info exists ytsrc($site)]} {
        return 0
    }
    set options [lindex $ytsrc($site) 4]
    if {[regexp watchlist $options]} {
        return 1
    } else {
        return 0
    }
}

proc get_channels_from_watchlist {data} {
    regsub -all {\"canonicalBaseUrl\":\"} $data \uffff data
    foreach line [split $data \uffff] {
        if {[regexp {^(/[^\"]+)\"} $line dummy channel]} {
            set found(https://www.youtube.com${channel}/videos) 1
        }
    }
    set list {}
    catch {
        set list [array names found]
    }
    return $list
}

proc is_audio_needed {site} {
    global ytsrc
    if {![info exists ytsrc($site)]} {
        return 0
    }
    set options [lindex $ytsrc($site) 4]
    if {[regexp noaudio $options]} {
        return 0
    } else {
        return 1
    }
}

proc skip_long_videos {site} {
    global ytsrc
    if {![info exists ytsrc($site)]} {
        return 0
    }
    set options [lindex $ytsrc($site) 4]
    if {[regexp skiplong $options]} {
        return 1
    } else {
        return 0
    }
}


proc main {} {
    global ytsrc ytdl config thumbs env
    set root [storage_root]/yt

    if {![file exists $root]} {
        puts "creating directory $root"
        file mkdir $root
    }
    if {![file exists $root/data]} {
        puts "creating directory $root/data"
        file mkdir $root/data
    } else {
        exec bash -c "find $root/data -name *.part -exec rm -v \{\} \\\;" >@ stdout 2>@ stdout
    }

    cleanup_old_files

    # Look for stuff to download (in reversed order in list)
    set worklist {}
    set maxlen 0
    foreach site [array names ytsrc] {
        set download_limit [lindex $ytsrc($site) 0]
        set storage_limit  [lindex $ytsrc($site) 1]
        set name           [lindex $ytsrc($site) 2]
        set url            [lindex $ytsrc($site) 3]

        puts "Getting list $site-$url"
        set ids($site) [get_ids $site $url $download_limit]
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
                puts "[format %3d [expr $i + 1]] $site-$id"
                lappend worklist [list $site $id]
            }
        }
    }


    # Download each video, oldest first
    foreach item $worklist {
        set site [lindex $item 0]
        set id   [lindex $item 1]

        if {[info exists env(YTONLY)] && "$id" != "$env(YTONLY)"} {
            continue
        }

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
            # Make sure all timestamps are separated by at least 1 second
            after 1000
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

        set getaudio [is_audio_needed $site]

        if {!$succeeded} {
            set filename unknown
            set succeeded 0
            set title ""
            set pubdate [clock milliseconds]
            set description ""

            if {$retrycount < $config(max-retry)} {
                if {[catch {
                    # Read the descriptions, etc
                    if {$getaudio || ![file exists $metadata]} {
                        puts "Downloading meta data from $url"
                        set data [exec wget --no-check-certificate --timeout=10 --tries=1 -q -O - $url 2> /dev/null | java FilterEmoji]
                        puts [string len $data]
                        set pat {"description":\{"simpleText":\"([^\"]+)}
                        puts $pat
                        regexp $pat $data dummy description
                        set title ""
                        regexp {<title>([^<]*)</title>} $data dummy title
                        regsub { - YouTube$} $title "" title
                        if {$title == ""} {
                            regexp {"title":\{"simpleText":\"([^\"]+)} $data dummy title
                        }
                        puts $title
                        puts $description
                        if {!$getaudio} {
                            # No need to get the audio. Just update the RSS feed with title and description
                            set update 1
                        }
                    }
                    if {$getaudio} {
                        puts "Downloading audio data from $url"
                        set filename [exec $ytdl --get-filename --no-mtime -o $filenamespec --audio-format m4a -x $url]
                        if {[regexp {[.]webm$} $filename]} {
                            regsub {[.]webm$} $filename .m4a filename
                        }
                        puts "filename = $filename"
                        set length [exec $ytdl --get-duration $url]
                        puts "length = $length"
                        if {[skip_long_videos $site] && [regexp {:.+:} $length]} {
                            puts "Skipping videos that are over 1 hour long"
                        } elseif {[regexp {【LIVE】} $title]} {
                            puts "Skipping LIVE videos"
                        } elseif {![file exists $filename]} {
                            exec $ytdl --no-mtime -o $filenamespec --audio-format m4a -x $url 2>@ stdout >@ stdout
                        }
                        set succeeded [file exists $filename]
                        if {!$succeeded} {
                            incr retrycount
                        }
                    }
                } errInfo]} {
                    puts "*** Failed to download audio data"
                    puts $errInfo
                }
                if {$getaudio || $update} {
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
                }
                if {$succeeded} {
                    set update 1
                }
            } else {
                puts "No: retrycount ($retrycount) is over limit ($config(max-retry)) for $url"
                puts "To retry this file even more:"
                puts "      rm $metadata"
            }
        }

        if {[file exists $metadata] && $update} {
            update_xml $site

            if {[info exists env(DEBUG)]} {
                puts "env(DEBUG)=$env(DEBUG)"
                incr env(DEBUG) -1
                if {$env(DEBUG) <= 0} {
                    exit
                }
            }
        }
    }
}

proc sort_by_newest_timestamp {a b} {
    global ts
    return [expr - $ts($a) + $ts($b)]
}

proc update_xml {site} {
    global ts ytsrc ytcfg thumbs
    set webroot $ytcfg(webroot)
    set need_audio [is_audio_needed $site]

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
	<sy:updateFrequency>12</sy:updateFrequency>

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
            set hasaudio    0

            if {[file exists $filename]} {
                set length [file size $filename]
                regsub "^.*/webrss/" $filename "" filename
                set hasaudio 1
            }
            regsub -all "\\\\n" $description "<br>\n" description

            catch {unset thumb}

            set link https://www.youtube.com/watch?v=$id
            if {[catch {
                set thumb $thumbs($id)
                #puts $thumb
                set thumb [redirect_image $thumb $link]
                #puts $thumb
                set description "$description <p> <img src=\"$thumb\"> "
            } xx]} {
                puts $xx
            }

            if {0 + $succeeded >= 0 || !$need_audio} {
                puts $fd "<item><title>$title</title>"
                puts $fd "<link>$link</link>"
                puts $fd "<dc:creator><!\[CDATA\[siran\]\]></dc:creator>"
                puts $fd "<pubDate>[clock_format [expr $pubdate / 1000]]</pubDate>"
                puts $fd "<category><!\[CDATA\[ラジオ\]\]></category>"
                puts $fd "<description><!\[CDATA\[$description\]\]></description>"
                if {$hasaudio} {
                    puts $fd "<enclosure url=\"$webroot/$filename\" length=\"$length\" type=\"audio/mpeg\" />"
                }
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
}

proc cleanup_old_files {} {
    global ytsrc keepfile env
    foreach site [array names ytsrc] {
        cleanup_timestamps $site
    }

    #parray keepfile

    foreach file [glob -nocomplain [storage_root]/yt/data/*] {
        set id [file root [file tail $file]]
        if {![info exists keepfile($id)]} {
            puts "$file <--- delete"
            if {![info exists env(CHECKDELETE)]} {
                file delete $file
            }
        }
    }
    if {[info exists env(CHECKDELETE)]} {
        exit
    }
}

proc cleanup_timestamps {site} {
    global ts ytsrc keepfile env
    set now [clock seconds]
    catch {unset ts}
    set download_limit [lindex $ytsrc($site) 0]
    set storage_limit  [lindex $ytsrc($site) 1]

    puts "Cleaning $site (limit = $storage_limit)"

    set sitedir [storage_root]/yt/$site
    if {![file exists $sitedir]} {
        return
    }
    set timestamps [glob $sitedir/*.tcl]
    foreach file $timestamps {
        # Dont source this file in case it's corrupt
        set ts($file) [file mtime $file]
    }

    # newest is on top
    set timestamps [lsort -command sort_by_newest_timestamp $timestamps]
    set n 0
    foreach file $timestamps {
        incr n
        if {$n > $storage_limit} {
            set limit limit
        } else {
            set limit "     "
        }
        set days [expr ($now - $ts($file)) / (3600 * 24)]
        if {$days >= 3} {
            set age "$days days"
        } else {
            set age ""
        }
        if {$age != "" && $limit == "limit"} {
            puts "$file $limit $age  <--- delete"
            if {![info exists env(CHECKDELETE)]} {
                file delete $file
            }
        } else {
            if {[info exists env(CHECKDELETE)]} {
                puts "$file $limit $age"
            }
            incr keepfile([file root [file tail $file]]) 1
        }
    }
}

main


# ./youtube-dl --get-duration --no-mtime -o '%(id)s.%(ext)s' -x https://www.youtube.com/watch?v=0v8VRhSZ7wc 
