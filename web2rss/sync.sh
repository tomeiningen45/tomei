root=$WEB2RSSROOT
while true; do
    echo start===========`date`
    tclsh 6park.tcl
    scp data/6park.xml $WEB2RSSROOT/test2.xml
    tclsh hkyahoo.tcl
    scp data/hkyahoo.xml $WEB2RSSROOT/test3.xml
    echo done============`date`
    sleep 3600
done
