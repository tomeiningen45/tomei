source [file dirname [info script]]/all_common.tcl

proc nhk_url_to_id {url} {
    set url [file tail $url]
    regsub {[.]html$} $url "" url
    return $url
}

proc nhk_trim_title {title} {
    set pat NHK\u30cb\u30e5\u30fc\u30b9
    regsub -all $pat $title "" title
    regsub {^[\u3000 ]+} $title "" title
    return $title
}

#foreach f {stdin stdout stderr} {
#    fconfigure $f -encoding shiftjis
#}
