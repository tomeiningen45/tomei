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
proc now {} {
    return [clock seconds]
}
