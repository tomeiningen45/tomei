while true; do
    echo SVN Update ===========`date`
    (cd ..; svn update --trust-server-cert --non-interactive)
    echo SVN Done ===========`date`

    cp sync.sh run_sync.sh
    sh run_sync.sh
    #sleep 1200
    sleep 600
done
