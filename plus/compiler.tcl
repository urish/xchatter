#! /usr/local/bin/tclsh8.0
# $Id: compiler.tcl,v 1.3 2001-07-31 11:30:49 uri Exp $

proc openf {name} {
    global fd
    set fd [open $name w]
}

proc putf {line} {
    global fd
    puts $fd $line
}

puts "Compiling XChatter plus, please hold on."
puts -nonewline "Reading src/xcplus.defs... "

set defdata [read [open src/xcplus.defs]]
array set defs $defdata

puts "version $defs(version)"

puts "Reading src/main.tcl... "

set xcpmainsrc [read [open src/main.tcl]]

regsub -all __XCPLUS_VERSION__ $xcpmainsrc $defs(version) xcpmainsrc
regsub -all __XCPLUS_NUMVER__ $xcpmainsrc $defs(numver) xcpmainsrc

puts "Reading XChatter extentions..."

foreach i [glob src/*.ext] {
    puts -nonewline "  $i... "
    flush stdout
    set fd [open $i r]
    set head [split [gets $fd]]
    set data [read $fd]
    close $fd
    set hop [lindex $head 0]
    if {$hop != "EXTENTION"} {
	puts "Header invalid."
	continue
    }
    set hdata [split [join [lrange $head 1 end]] -]
    set extname [lindex $hdata 0]
    set extver [lindex $hdata 1]
    set extnumver [lindex $hdata 2]
    set extentions($extname,version) [list $extver $extnumver]
    set extentions($extname,script) [join [split $data \\] \xff]
    puts "$extname v$extver"
}

regsub -all __EXTENTIONS__ $xcpmainsrc [join [split [join [split [list [array get extentions]] \xff] \\\\] &] \\&] xcpmainsrc

puts -nonewline "Building output file... "

openf "xcplus.xcp"
putf "# xchatter-0.5 ~$defs(version)~50~XChatter plus plugin"
putf "# xchatter-plus ~$defs(version)~$defs(numver)~$defs(minver)~$defs(maxver)"
putf ""
putf "# XChatter plus, compiled at [clock format [clock seconds]]."
putf ""
putf "catch {xcplus::destroy}"
putf {proc destroy_widget {args} {eval destroy $args}}
putf {proc xcplus {args} {eval xcplus::[lindex $args 0] [lrange $args 1 end]}}
putf ""
putf $xcpmainsrc
putf "# Initilize the xchatter plus extention"
putf "xcplus::init"
putf "return"

puts "DONE"
