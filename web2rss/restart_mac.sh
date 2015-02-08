#! /bin/bash
#
# Run this script as you log into the mac account
# It restarts both the HTTP server and the main sync loop

# We no longer SCP to the remote site. Instead, the host that runs the sync script also
# serves the RSS feeds, etc.

export NOSCP=1

echo mypid=$$

# Launch new apps

ps

for app in main_loop http_server; do
    LOG=/tmp/web2rss_$app
    PROG=${HOME}/tomei/web2rss/$app.sh

    echo ----------------------------------------------------------------------
    echo "(Re)launching $PROG"
    echo ----------------------------------------------------------------------

    # Kill older processes (by process group)
    SIGNAL=-TERM
    while true; do
        FOUND=0
        for pid in $(pgrep -f $PROG); do
            if test "$pid" != "$$"; then
                thepgid=$(ps -eo pid,pgid | while read p pgid; do 
                        if test "$p" = "$pid"; then
                            echo "$pgid"
                            break
                        fi
                    done)
                echo "found main process PID = $pid, PGID = $thepgid"
                if test "$thepgid" != ""; then
                    ps -eo pid,pgid | while read p pgid; do
                        if test "$pgid" = "$thepgid"; then
                            bash -c "set -x; kill $SIGNAL $p"
                        fi
                    done
                    FOUND=1
                fi
            fi
        done

        if test "$FOUND" = "0"; then
            break
        else
            sleep 5
            SIGNAL=-9
        fi
    done

    echo "NO MORE OLD PROCESSES"

    for n in 5 4 3 2 1; do
        mv -f $LOG.$n $LOG.$(expr $n + 1)
    done

    if test "$1" != "-k"; then
        nohup bash -c "$PROG 2>&1 > $LOG.1" > /dev/null &
    fi
done

    
