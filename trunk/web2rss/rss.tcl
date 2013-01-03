#----------------------------------------------------------------------
# Shared scripts [to be moved to separate file]
#----------------------------------------------------------------------

proc wget {url {encoding {utf-8}}} {
    set data ""
    catch {
        set fd [open "|wget -q -O - $url 2> /dev/null"]
        fconfigure $fd -encoding $encoding
        set data [read $fd]
    }
    catch {
        close $fd
    }
    return $data
}

proc makelist {data splitter} {
    regsub -all $splitter $data \uFFFF data
    set list [split $data \uFFFF]
    return [lrange $list 1 end]
}

proc getcachefile {localname} {
    global datadir

    return $datadir/[file tail $localname]
}

proc getfile {link localname {encoding utf-8}} {
    set fname [getcachefile $localname]

    if {![file exists $fname]} {
        set data [wget $link $encoding]
        set fd [open $fname w+]
        fconfigure $fd -encoding $encoding
        puts -nonewline $fd $data
        close $fd
    } else {
        set fd [open $fname]
        fconfigure $fd -encoding $encoding
        set data [read $fd]
        close $fd
    }
    return $data
}

proc makeitem {title link data date} {
    set t {
        <item>
        <title><![CDATA[TITLE]]></title>
        <link>LINK_URL</link>
        <description><![CDATA[DESCRIPTION]]></description>
        <pubDate>DATE</pubDate>
        </item>
    }

    catch {
        # if passed in an integer, make it into a date string
        set date [clock format $date]
    }

    regsub -all TITLE       $t $title t
    regsub -all LINK_URL    $t $link  t
    regsub -all DATE        $t $date t

    regsub DESCRIPTION $t \uFFFF t
    set list [split $t \uFFFF]
    set t [lindex $list 0]$data[lindex $list 1]
    return $t
}

proc now {} {
    return [clock seconds]
}
