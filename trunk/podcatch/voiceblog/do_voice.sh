#! /bin/bash

# sh do_voice.sh 3
# sh do_voice.sh 1 mote

export VOICEBLOG_VERBOSE=1
#export VOICEBLOG_STARTMONTH=10

if test "$*" = ""; then
    e=1
else
    e=$*
fi

while true; do
    echo ================ `date`
    time tclsh voiceblog_get.tcl `tclsh voiceblog_titles.tcl 10000 $e`
    sleep 3600
done
