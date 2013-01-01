set map {
    {
    main "Business & Finance News | Yahoo Finance" 
        http://finance.yahoo.com/news/;_ylt=AmEFggb5wb3RosqZH6iKkXKhuYdG;_ylu=X3oDMTI0ZzNjZmE2BG1pdANTdWJzY3JpYmUgYW5kIFNpdGUgSW5kZXggVG9wIFN0b3JpZXMEcG9zAzYEc2VjA01lZGlhUlNTRWRpdG9yaWFs;_ylg=X3oDMTFzdHZoMTdhBGludGwDdXMEbGFuZwNlbi11cwRwc3RhaWQDBHBzdGNhdANuZXdzfHByb3ZpZGVycwRwdANzZWN0aW9ucw--;_ylv=3?format=rss
    }
    {
    commodity "Commodities News and Information | Yahoo Finance"
        http://finance.yahoo.com/news/category-commodities/rss;_ylt=ApXoeBtSjABggoK1add9fmWhuYdG;_ylu=X3oDMTI0M29vYW91BG1pdANTdWJzY3JpYmUgYW5kIFNpdGUgSW5kZXggVVMgTWFya2V0cwRwb3MDMTgEc2VjA01lZGlhUlNTRWRpdG9yaWFs;_ylg=X3oDMTFzdHZoMTdhBGludGwDdXMEbGFuZwNlbi11cwRwc3RhaWQDBHBzdGNhdANuZXdzfHByb3ZpZGVycwRwdANzZWN0aW9ucw--;_ylv=3
    }
    {
    economy "Economy, Government & Policy News | Yahoo Finance"
        http://finance.yahoo.com/news/category-economy-govt-and-policy/rss;_ylt=ApsOxf3kAB7rj2QMqxWDwS.huYdG;_ylu=X3oDMTI1bHFtOWR2BG1pdANTdWJzY3JpYmUgYW5kIFNpdGUgSW5kZXggR2VuZXJhbCBOZXdzBHBvcwM2BHNlYwNNZWRpYVJTU0VkaXRvcmlhbA--;_ylg=X3oDMTFzdHZoMTdhBGludGwDdXMEbGFuZwNlbi11cwRwc3RhaWQDBHBzdGNhdANuZXdzfHByb3ZpZGVycwRwdANzZWN0aW9ucw--;_ylv=3
    }
    {
    international "International"
        http://finance.yahoo.com/news/category-economy/rss;_ylt=AuZRgW6lfCsYGR3_d_MoBhqhuYdG;_ylu=X3oDMTI2cnR0OGtvBG1pdANTdWJzY3JpYmUgYW5kIFNpdGUgSW5kZXggR2VuZXJhbCBOZXdzBHBvcwMxMgRzZWMDTWVkaWFSU1NFZGl0b3JpYWw-;_ylg=X3oDMTFzdHZoMTdhBGludGwDdXMEbGFuZwNlbi11cwRwc3RhaWQDBHBzdGNhdANuZXdzfHByb3ZpZGVycwRwdANzZWN0aW9ucw--;_ylv=3
    }
    {
    investing "Investing Ideas & Strategies | Yahoo Finance"
        http://finance.yahoo.com/news/category-ideas-and-strategies/rss;_ylt=AkPljMBDO2lA7YxU15jlwSyhuYdG;_ylu=X3oDMTI0dTRkanY1BG1pdANTdWJzY3JpYmUgYW5kIFNpdGUgSW5kZXggVVMgTWFya2V0cwRwb3MDMjcEc2VjA01lZGlhUlNTRWRpdG9yaWFs;_ylg=X3oDMTFzdHZoMTdhBGludGwDdXMEbGFuZwNlbi11cwRwc3RhaWQDBHBzdGNhdANuZXdzfHByb3ZpZGVycwRwdANzZWN0aW9ucw--;_ylv=3
    }
    {
    tech "Technology"
        http://finance.yahoo.com/news/sector-technology/rss;_ylt=Aqdb_Je_9Tx83qfarY3eOmmhuYdG;_ylu=X3oDMTIxbGJnMjFpBG1pdANTdWJzY3JpYmUgYW5kIFNpdGUgSW5kZXggU2VjdG9ycwRwb3MDMjEEc2VjA01lZGlhUlNTRWRpdG9yaWFs;_ylg=X3oDMTFzdHZoMTdhBGludGwDdXMEbGFuZwNlbi11cwRwc3RhaWQDBHBzdGNhdANuZXdzfHByb3ZpZGVycwRwdANzZWN0aW9ucw--;_ylv=3
    }
}


foreach item $map {
    set name [lindex $item 0]
    set title [lindex $item 1]
    set url [lindex $item 2]

    if {"$argv" == "" || [lsearch $argv $name] >= 0} {
        catch {
            exec tclsh [file dirname [info script]]/yahoofn.tcl $name $title [list $url] 2>@ stdout >@ stdout
        } 
    }
}

#     scp data/yahoofn_*.xml $WEB2RSSROOT/
