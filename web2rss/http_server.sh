#! /bin/bash
if test "$HTTP_PORT" != ""; then
    ARG="-port $HTTP_PORT"
fi
exec tclsh tclhttpd3.5.1/bin/httpd.tcl $ARG



