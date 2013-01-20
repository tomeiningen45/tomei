set map {
    http://blog.goo.ne.jp/genre_rss/1182 fishing        釣り      
    http://blog.goo.ne.jp/genre_rss/1136 eating_around  食べ歩き   
    http://blog.goo.ne.jp/genre_rss/1053 drive          ドライブ 
    http://blog.goo.ne.jp/genre_rss/1356 walking        散歩
    http://blog.goo.ne.jp/genre_rss/1051 shopping       ショッピング 
    http://blog.goo.ne.jp/genre_rss/1148 overseas       海外
    http://blog.goo.ne.jp/genre_rss/1144 interior       インテリア
    http://blog.goo.ne.jp/genre_rss/1144 craft          クラフト
    http://blog.goo.ne.jp/genre_rss/1215 collection     コレクション
}

foreach {url name title} $map {
    if {"$argv" == "" || [lsearch $argv $name] >= 0} {
        catch {
            exec tclsh [file dirname [info script]]/gooblog.tcl $name $title $url 2>@ stdout >@ stdout
        } 
    }
}

#     scp data/gooblog_*.xml $WEB2RSSROOT/rss/