set now [clock seconds]
set count 0
set remain 0
foreach file [exec sh -c "find data/*/ -type f"] {
    if {$now - [file mtime $file] > 3 * 86400} {
	file delete $file
	incr count
    } else {
	incr remain
    }
}

puts "Deleted $count files; remain $remain files"

