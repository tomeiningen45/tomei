root=$WEB2RSSROOT

SCP=$RSS_SCP
if test "$SCP" = ""; then
    SCP=scp
fi

function waitscp () {
    echo wait to scp; sleep 5;
}

if test "$NOSCP" != 0; then
    SCP=true
    function waitscp () {
        true
    }
fi

function dosync () {
    if test "$2" = ""; then
        dest=$WEB2RSSROOT/rss/
    else
        dest=$2
    fi
    waitscp
    $SCP $1 $dest &
}


##while true; do
    echo start===========`date`

if test -f sync_cnbeta.file; then    
    tclsh cnbeta.tcl
    waitscp
    $SCP data/cnbeta.xml $root/cnbeta.xml &

else

    #tclsh autotrader.tcl
    #dosync data/autotrader.xml $WEB2RSSROOT/rss/autotrader2.xml

    #env AUTOTRADER_REMOTE=1 tclsh autotrader.tcl
    #dosync data/autotrader_remote.xml $WEB2RSSROOT/rss/autotrader_remote2.xml

    #env AUTOTRADER_AUTO=1 tclsh autotrader.tcl
    #dosync data/autotrader_auto.xml $WEB2RSSROOT/rss/autotrader_auto1.xml

    #env AUTOTRADER_AUTO_REMOTE=1 tclsh autotrader.tcl
    #dosync data/autotrader_auto_remote.xml  $WEB2RSSROOT/rss/autotrader_auto_remote1.xml

    #env AUTOTRADER_CAYMAN=1 tclsh autotrader.tcl
    #dosync data/autotrader_cayman.xml

    #env AUTOTRADER_CAYMAN_REMOTE=1 tclsh autotrader.tcl
    #dosync data/autotrader_cayman_remote.xml

    tclsh 6park.tcl
    waitscp
    $SCP data/6park.xml $root/test2.xml &

  if false; then
    tclsh 6park_forum_top.tcl
    waitscp
    $SCP data/6park-*.xml $root/rss/ &

    tclsh wforum.tcl
    waitscp
    $SCP data/wforum.xml $root/wforum.xml &

    tclsh yahoohk.tcl
    waitscp
    $SCP data/hkyahoo.xml $root/rss/hkyahoo.xml &

#    tclsh cnbeta.tcl
#    waitscp
#    $SCP data/cnbeta.xml $root/cnbeta.xml &

#   tclsh iza.tcl
#   waitscp
#   $SCP data/iza.xml $root/iza.xml &

    tclsh yahoofn.tcl 
    waitscp
    $SCP data/yahoofn_*.xml $root/ &

    tclsh bloomberg_top.tcl 
    waitscp
    $SCP data/bloomberg_*.xml $root/ &

    tclsh zasshi.tcl 
    waitscp
    $SCP data/zasshi*.xml $root/rss/ &

    tclsh gooblog_top.tcl 
    waitscp
    $SCP data/gooblog_*.xml $WEB2RSSROOT/rss/ &

#   tclsh tiexue.tcl 
#   waitscp
#   $SCP data/tiexue.xml $WEB2RSSROOT/rss/ &

    tclsh rennlist.tcl 
    waitscp
    $SCP data/rennlist.xml $WEB2RSSROOT/rss/ &

    tclsh register.tcl 
    waitscp
    $SCP data/register.xml $WEB2RSSROOT/rss/ &

    tclsh craigslist.tcl 
    waitscp
    $SCP data/craigslist.xml $WEB2RSSROOT/rss/ &

    env CRAIG_LOCAL=1 tclsh craigslist.tcl 
    dosync data/craigslist_local.xml

    tclsh fortune.tcl 
    waitscp
    $SCP data/fortune.xml $WEB2RSSROOT/rss/ &

    for site in ebay_911 ebay_930 mohr pelican roadsport; do 
        tclsh multicar.tcl $site
        waitscp
        $SCP data/$site.xml $WEB2RSSROOT/rss/ &
    done
  fi
fi

    tclsh delete_old_files.tcl

    echo done============`date`
##    sleep 1200
##done
