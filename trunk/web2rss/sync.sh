root=$WEB2RSSROOT

SCP=$RSS_SCP
if test "$SCP" = ""; then
    SCP=scp
fi

##while true; do
    echo start===========`date`

    tclsh 6park.tcl
    $SCP data/6park.xml $root/test2.xml

    tclsh wforum.tcl
    $SCP data/wforum.xml $root/wforum.xml

    tclsh yahoohk.tcl
    $SCP data/hkyahoo.xml $root/test3.xml

    tclsh cnbeta.tcl
    $SCP data/cnbeta.xml $root/cnbeta.xml

    tclsh iza.tcl
    $SCP data/iza.xml $root/iza.xml

    tclsh yahoofn_top.tcl 
    $SCP data/yahoofn_*.xml $root/

    tclsh bloomberg_top.tcl 
    $SCP data/bloomberg_*.xml $root/

    tclsh zasshi.tcl 
    $SCP data/zasshi*.xml $root/rss/

    tclsh gooblog_top.tcl 
    scp data/gooblog_*.xml $WEB2RSSROOT/rss/

    tclsh delete_old_files.tcl

    echo done============`date`
##    sleep 1200
##done
