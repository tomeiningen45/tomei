root=$WEB2RSSROOT
while true; do
    echo start===========`date`

    tclsh 6park.tcl
    scp data/6park.xml $WEB2RSSROOT/test2.xml

    tclsh wforum.tcl
    scp data/wforum.xml $WEB2RSSROOT/wforum.xml

    tclsh yahoohk.tcl
    scp data/hkyahoo.xml $WEB2RSSROOT/test3.xml

    tclsh cnbeta.tcl
    scp data/cnbeta.xml $WEB2RSSROOT/cnbeta.xml

    tclsh yahoofn_top.tcl 
    scp data/yahoofn_*.xml $WEB2RSSROOT/

    echo done============`date`
    sleep 3600
done
