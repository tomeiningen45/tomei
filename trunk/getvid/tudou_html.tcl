fconfigure stdin -encoding utf-8
fconfigure stdout -encoding utf-8

set data [read stdin]

regsub -all "<a title=\"" $data \uffff data
foreach line [split $data \uffff] {
    if {[regexp "href=\"(http://www.tudou.com/listplay/\[^\"\]+)\"" $line dummy link] &&
        [regexp "^(\[^\"\]+)" $line dummy name]} {
        if {![info exists seen($link)]} {
            set seen($link) 1
            puts "$link $name"
        }
    }
}
