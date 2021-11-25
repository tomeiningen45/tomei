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

