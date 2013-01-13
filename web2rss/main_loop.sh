sh side_loop.sh &

while true; do
    echo SVN Update ===========`date`
    svn update
    echo SVN Done ===========`date`

    cp sync.sh run_sync.sh
    sh run_sync.sh
    sleep 1200
done
