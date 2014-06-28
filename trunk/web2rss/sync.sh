root=$WEB2RSSROOT

SCP=$RSS_SCP
if test "$SCP" = ""; then
    SCP=scp
fi

function dosync () {
    if test "$2" = ""; then
        dest=$WEB2RSSROOT/rss/
    else
        dest=$2
    fi
    echo wait to scp; sleep 5;
    $SCP $1 $dest &
}


##while true; do
    echo start===========`date`

if test -f sync_cnbeta.file; then    
    tclsh cnbeta.tcl
    echo wait to scp; sleep 5;
    $SCP data/cnbeta.xml $root/cnbeta.xml &

else

    tclsh 6park.tcl
    echo wait to scp; sleep 5;
    $SCP data/6park.xml $root/test2.xml &

    tclsh 6park_forum_top.tcl
    echo wait to scp; sleep 5;
    $SCP data/6park-*.xml $root/rss/ &

    tclsh wforum.tcl
    echo wait to scp; sleep 5;
    $SCP data/wforum.xml $root/wforum.xml &

    tclsh yahoohk.tcl
    echo wait to scp; sleep 5;
    $SCP data/hkyahoo.xml $root/rss/hkyahoo.xml &

#    tclsh cnbeta.tcl
#    echo wait to scp; sleep 5;
#    $SCP data/cnbeta.xml $root/cnbeta.xml &

    tclsh iza.tcl
    echo wait to scp; sleep 5;
    $SCP data/iza.xml $root/iza.xml &

    tclsh yahoofn.tcl 
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

    tclsh rennlist.tcl 
    echo wait to scp; sleep 5;
    $SCP data/rennlist.xml $WEB2RSSROOT/rss/ &

    tclsh register.tcl 
    echo wait to scp; sleep 5;
    $SCP data/register.xml $WEB2RSSROOT/rss/ &

    tclsh craigslist.tcl 
    echo wait to scp; sleep 5;
    $SCP data/craigslist.xml $WEB2RSSROOT/rss/ &

    env CRAIG_LOCAL=1 tclsh craigslist.tcl 
    dosync data/craigslist_local.xml

    tclsh autotrader.tcl
    dosync data/autotrader.xml $WEB2RSSROOT/rss/autotrader1.xml

    #env AUTOTRADER_REMOTE=1 tclsh autotrader.tcl
    #dosync data/autotrader_remote.xml

    tclsh fortune.tcl 
    echo wait to scp; sleep 5;
    $SCP data/fortune.xml $WEB2RSSROOT/rss/ &

    for site in ebay_911 ebay_930 mohr pelican roadsport; do 
        tclsh multicar.tcl $site
        echo wait to scp; sleep 5;
        $SCP data/$site.xml $WEB2RSSROOT/rss/ &
    done

fi

    tclsh delete_old_files.tcl

    echo done============`date`
##    sleep 1200
##done
