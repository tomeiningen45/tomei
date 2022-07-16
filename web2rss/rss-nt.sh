#! /bin/bash
#
# rss-nt.sh
#      This is the main program that starts up the rss-nt.tcl engine. This script
#      pipes the stdout/stderr to /tmp/rss-nt.log

while true; do
    if [[ -f update.git ]]; then
        git pull
    fi
    echo ----------------------------------------------------------------------
    echo Restarting ..... $(date)
    echo ----------------------------------------------------------------------
    if [[ -z "$DEBUG" ]]; then
        tclsh $(dirname $0)/weather.tcl
    fi

    log=/tmp/rss-nt.log

    for i in 5 4 3 2 1; do
        j=$(expr $i + 1)
        if [[ -f $log.$i ]]; then
            mv $log.$i $log.$j
        fi
    done

    if [[ -f $log ]]; then
        mv $log $log.1;
    fi

    if [[ -z "$DEBUG" ]]; then
        tclsh $(dirname $0)/rss-nt.tcl 2>&1 > $log
    else
        tclsh $(dirname $0)/rss-nt.tcl 2>&1 | tee $log
        exit
    fi
done
