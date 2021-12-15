# See how tclsh can handle emoji
#
#
# This page has ＜チェックしてね(emoji)＞
set url https://www.youtube.com/watch?v=XdGWxMXwNZI
set data [exec wget --no-check-certificate --timeout=10 --tries=1 -q -O - $url | java -cp . FilterEmoji 2> /dev/null]

regsub .*＜チェックしてね $data "" data
regsub (＞..........).* $data "\\1" data

puts ====$data====
set n 20
foreach c [split $data ""] {
    scan $c %c a
    puts [format %x $a]
    incr n -1
    if {$n < 0} {
        break;
    }
}

