set map {
    http://blog.goo.ne.jp/genre_rss/1182 fishing        釣り      
    http://blog.goo.ne.jp/genre_rss/1136 eating_around  食べ歩き   
    http://blog.goo.ne.jp/genre_rss/1053 drive          ドライブ 
    http://blog.goo.ne.jp/genre_rss/1356 walking        散歩
    http://blog.goo.ne.jp/genre_rss/1051 shopping       ショッピング 
}

foreach {url name title} $map {
    if {"$argv" == "" || [lsearch $argv $name] >= 0} {
        catch {
            exec tclsh [file dirname [info script]]/gooblog.tcl $name $title $url 2>@ stdout >@ stdout
        } 
    }
}

#     scp data/gooblog_*.xml $WEB2RSSROOT/rss/
