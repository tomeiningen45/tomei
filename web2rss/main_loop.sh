#! /bin/bash

while true; do
    echo SVN Update ===========`date`
    (cd ..; svn update --trust-server-cert --non-interactive)
    echo SVN Done ===========`date`

    start=`date`
    cp sync.sh run_sync.sh
    time sh run_sync.sh
    #sleep 1200
    echo "START=$start"
    echo "  END=`date`"
    sleep 600
done
