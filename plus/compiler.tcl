#! /usr/local/bin/tclsh8.0
# $Id: compiler.tcl,v 1.6 2002-03-15 19:57:27 urish Exp $

proc openf {name} {
    global fd
    set fd [open $name w]
}

proc putf {line} {
    global fd
    puts $fd $line
}

proc closef {} {
    global fd
    close $fd
}

proc compile_help {data} {
    global no_standalone help
    if ![info exists no_standalone] {
	foreach i {../help/compile.tcl help/compile.tcl help.tcl compile.tcl} {
	    if [file readable $i] {
		set compiler $i
		break
	    }
	}
	if [info exists compiler] {
	    set no_standalone 1
	    source $compiler
	} else {
	    puts "Can't find help compiler."
	    return ""
	}
    }
    init_tags
    process_helpfile_data $data
    set helpdata [array get help]
    catch {unset help}
    return $helpdata
}

proc replace_include {data basedir} {
    set include_start "<@INCLUDE "
    set include_end ">"
    while {[set incpos [string first $include_start $data]] >= 0} {
	set before [string range $data 0 [expr $incpos - 1]]
	set after [string range $data [expr $incpos + [string length $include_start]] end]
	set incend [string first $include_end $after]
	if {$incend == -1} {
	    return $data
	}
	set fname [string trim [string range $after 0 [expr $incend - 1]]]
	if ![file readable $basedir/$fname] {
	    error "can't read from included file '$fname'"
	}
	puts -nonewline "+"
	set fd [open $basedir/$fname r]
	set fdata [read $fd]
	close $fd
	set data $before$fdata[string range $after [expr $incend + [string length $include_end]] end]
    }
    return $data
}

proc strtok {varname} {
    upvar $varname var
    set result ""
    while {$result == ""} {
	set result [lindex $var 0]
	set var [lrange $var 1 end]
    }
    return $result
}

proc readext {fname basedir} {
    global extensions
    puts -nonewline "  $fname... "
    flush stdout
    if [file exists $basedir/precompile.tcl] {
	if ![source $basedir/precompile.tcl] {
	    if [info exists error] {
		puts "Error in precompile: $error"
	    } else {
		puts "Unknown error in precompile."
	    }
	    return 0
	}
    }
    set fd [open $fname r]
    set head [split [gets $fd]]
    set data [read $fd]
    close $fd
    if [catch {replace_include $data $basedir} data] {
	puts "error: $data"
	return
    }
    set hop [strtok head]
    if {$hop != "EXTENTION"} {
	puts "Header invalid."
	return
    }
    set extname [strtok head]
    set extver 1.0
    set extbuild 1
    while {$head != ""} {
	set name [strtok head]
	set value [strtok head]
	switch -- [string toupper $name] {
	    VERSION {
		set extver $value
	    }
	    BUILD {
		set extbuild $value
	    }
	    HELP {
		set helpfile $value
	    }
	}
    }
    set extensions($extname,version) [list $extver $extbuild]
    set extensions($extname,script) [join [split $data \\] \xff]
    if [info exists helpfile] {
	if [file readable $basedir/$helpfile] {
	    set helpfd [open $basedir/$helpfile]
	    set extensions($extname,help) [compile_help [read $helpfd]]
	    close $helpfd
	    if {$extensions($extname,help) == ""} {
		return
	    }
	} else {
	    puts "Help file not found."
	    return
	}
    }
    puts "$extname v$extver"
}

puts "Reading XChatter extensions..."

foreach i [glob src/*.ext] {
    readext $i "src"
}

foreach i [glob -nocomplain src/*] {
    if {[lindex $i 0] == "."} {
	continue
    }
    if [file exists $i/main.tcl] {
	readext $i/main.tcl $i
    }
}

puts -nonewline "Building output files... "

foreach i [array names extensions *,version] {
    set name [lindex [split $i ,] 0]
    openf "$name.xcp"
    putf "# 1 EXT $name [join $extensions($i) " "] 0 1"
    putf "# XChatter plus extension $name, compiled at [clock format [clock seconds]]."
    putf "# END HEADER."
    if [info exists extensions($name,help)] {
	set help $extensions($name,help)
    } else {
	set help ""
    }
    putf "[join [split [list $extensions($name,script) $help] \xff] \\]"
    closef
}

puts "DONE"
