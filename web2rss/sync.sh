root=$WEB2RSSROOT
##while true; do
    echo start===========`date`

    tclsh 6park.tcl
    scp data/6park.xml $root/test2.xml

    tclsh wforum.tcl
    scp data/wforum.xml $root/wforum.xml

    tclsh yahoohk.tcl
    scp data/hkyahoo.xml $root/test3.xml

    tclsh cnbeta.tcl
    scp data/cnbeta.xml $root/cnbeta.xml

    tclsh iza.tcl
    scp data/iza.xml $root/iza.xml

    tclsh yahoofn_top.tcl 
    scp data/yahoofn_*.xml $root/

    tclsh bloomberg_top.tcl 
    scp data/bloomberg_*.xml $root/

    echo done============`date`
##    sleep 1200
##done
