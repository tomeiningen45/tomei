set map {
    top        http://www.bloomberg.com/news/ 
    main       http://www.bloomberg.com/news/worldwide/
    asia       http://www.bloomberg.com/news/asia/
    economy    http://www.bloomberg.com/news/economy/
    currencies http://www.bloomberg.com/news/currencies/
    stocks     http://www.bloomberg.com/news/stocks/
}


foreach {name url} $map {
    if {"$argv" == "" || [lsearch $argv $name] >= 0} {
        catch {
            exec tclsh [file dirname [info script]]/bloomberg.tcl $name $url 2>@ stdout >@ stdout
        } 
    }
}

#     scp data/bloomberg_*.xml $WEB2RSSROOT/
