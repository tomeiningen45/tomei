# A simple test to see if encoding works well on Windows 10.
#
set url https://www.youtube.com/watch?v=U7lpavN3qDE
set fd [open "|wget --no-check-certificate --timeout=10 --tries=1 -q -O - $url | java FilterEmoji"]
puts [fconfigure $fd]
fconfigure $fd -encoding utf-8
set data [read $fd]
close $fd

regsub -all {.*<title>} $data "" data
regsub -all {</title>.*} $data "" data

set fd [open data.txt w+]
puts [fconfigure $fd]
fconfigure $fd -encoding utf-8
puts $fd $data
close $fd
