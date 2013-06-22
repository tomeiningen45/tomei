root=$WEB2RSSROOT

SCP=$RSS_SCP
if test "$SCP" = ""; then
    SCP=scp
fi

##while true; do
    echo start===========`date`

    tclsh 6park.tcl
    echo wait to scp; sleep 5;
    $SCP data/6park.xml $root/test2.xml &

    tclsh wforum.tcl
    echo wait to scp; sleep 5;
    $SCP data/wforum.xml $root/wforum.xml &

    tclsh yahoohk.tcl
    echo wait to scp; sleep 5;
    $SCP data/hkyahoo.xml $root/test3.xml &

#    tclsh cnbeta.tcl
#    echo wait to scp; sleep 5;
#    $SCP data/cnbeta.xml $root/cnbeta.xml &

    tclsh iza.tcl
    echo wait to scp; sleep 5;
    $SCP data/iza.xml $root/iza.xml &

    tclsh yahoofn_top.tcl 
    echo wait to scp; sleep 5;
    $SCP data/yahoofn_*.xml $root/ &

    tclsh bloomberg_top.tcl 
    echo wait to scp; sleep 5;
    $SCP data/bloomberg_*.xml $root/ &

    tclsh zasshi.tcl 
    echo wait to scp; sleep 5;
    $SCP data/zasshi*.xml $root/rss/ &

    tclsh gooblog_top.tcl 
    echo wait to scp; sleep 5;
    $SCP data/gooblog_*.xml $WEB2RSSROOT/rss/ &

    tclsh tiexue.tcl 
    echo wait to scp; sleep 5;
    $SCP data/tiexue.xml $WEB2RSSROOT/rss/ &

    tclsh delete_old_files.tcl

    echo done============`date`
##    sleep 1200
##done