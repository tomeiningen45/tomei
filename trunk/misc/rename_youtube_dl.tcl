#!/bin/sh
#-*-tcl-*-
# the next line restarts using tclsh \
exec tclsh "$0" ${1+"$@"}

foreach i $argv {
    regsub {[-][^-][^-][^-][^-][^-][^-][^-][^-][^-][^-][^-][.]} $i "." j
    set done 0

    if {"$i" != "$j"} {
        puts ==>$j
        if {![info exist env(TESTONLY)]} {
            file rename $i $j
        }
        set done 1
    } else {
        if {[regexp {([-]...........[.])([^.]+)$} $i dummy code]} {
            puts "$i >>>>>>>OK> '$code'? y/n"
            if {[string trim [gets stdin]] == "y"} {
                regsub {[-]...........[.]} $i "." j
                puts ==>$j
                if {![info exist env(TESTONLY)]} {
                    file rename "$i" "$j"
                }
                set done 1
            }
        }
    }

    if {!$done} {
        puts ">>>$i"
    }
}

