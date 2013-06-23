echo SIDE_SYNC start ===========`date`

if test -f sync_cnbeta.file; then
    tclsh cnbeta_comments.tcl
else
    tclsh yahoohk_comments.tcl
fi

echo SIDE_SYNC done============`date`
