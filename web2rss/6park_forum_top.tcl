set map {
    {stock 谈股论金 http://site.6park.com/chan4/}
    {econ  经济观察 http://site.6park.com/finance/}
    {mil   网际谈兵 http://site.6park.com/military/}
    {car   车迷沙龙 http://site.6park.com/enter7/index.php}
}


foreach item $map {
    set name [lindex $item 0]
    set title [lindex $item 1]
    set url [lindex $item 2]

    if {"$argv" == "" || [lsearch $argv $name] >= 0} {
        catch {
            exec tclsh [file dirname [info script]]/6park_forum.tcl $name $url $title 2>@ stdout >@ stdout
        } 
    }
}

#     scp data/yahoofn_*.xml $WEB2RSSROOT/
