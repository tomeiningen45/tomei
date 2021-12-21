package require ncgi

proc clock_format {date} {
    return [clock format $date -format {%a, %d %b %Y %T %Z}]
}

proc storage_root {} {
    
    foreach d {
        /opt/local/www/apache2/html/webrss
        /usr/local/var/www/webrss
        /var/www/html/webrss
    } {
        if {[file exists $d] && [file isdir $d]} {
            return $d
        }
    }

    set a /tmp/webrss
    file mkdir $a
    return $a
}


set g(webroot) ""

proc redirect_image {img referrer} {
    global g

    set pat {[@^]}
    if {[regexp $pat $img] || [regexp $pat $referrer]} {
        return ""
    }

    set s [ncgi::encode $img^$referrer].jpg
    regsub -all {%2F} $s "@" s

    return $g(webroot)/hooks/im2/$s
}

catch {
    source [file dirname [info script]]/config.tcl
}

