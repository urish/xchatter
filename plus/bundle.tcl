#! /usr/local/bin/tclsh8.0
# $Id: bundle.tcl,v 1.1 2002-03-28 22:28:55 urish Exp $

# bundles all the .xcp files into a single xcplus.xcp file.
set output [open ../xcplus.xcp w]
set index 0
foreach f [glob *.xcp] {
    puts "Adding file $f..."    
    set fd [open $f]
    set idxlist ""
    while {![eof $fd]} {
        set ln [string trim [gets $fd]]
        if {[string index $ln 0] != "#"} {
	    break
	}
	if {[string match "#*END HEADER*" [string toupper $ln]]} {
	    break
	}
	set sln [split $ln]
	if {[lrange $sln 1 2] == "1 EXT"} {
	    set start [lindex $sln 6]
	    set end [lindex $sln 7]
	    set diff [expr $end - $start + 1]
	    puts $output "# 1 EXT [join [lrange $sln 3 5]] $index [expr $index + $diff - 1]"
	    incr index $diff
	    lappend idxlist $start $end
	}
    }
    set restfile [read $fd]
    foreach {start end} $idxlist {
	lappend data [lrange $restfile $start $end]
    }
    close $fd
}
puts $output "# XChatter plus extension pack; bundled at [clock format [clock seconds]]."
puts $output "# END HEADER."
puts $output "[join $data]"
close $output
puts "Done."

