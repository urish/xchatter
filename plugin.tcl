# XChatter extension support
# $Id: plugin.tcl,v 1.3 2002-03-19 11:20:11 urish Exp $

proc make_extension_index {} {
    global extensions
    catch {unset extensions}
    foreach dir {. plugins plus xcplus} {
	foreach file [glob -nocomplain $dir/*.xcp] {
	    if [file readable $file] {
		lappend files $file
	    }
	}
    }
    if ![info exists files] {
	return 0
    }
    foreach file $files {
	set fd [open $file]
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
		lappend extensions([string tolower [lindex $sln 3]]) [concat [list $file] [lrange $sln 4 end]]
	    }
	}
	close $fd
    }
    return 1
}

proc load_extension_from_file {namespace name scriptidx helpidx} {
    global helptext
    set fd [open $name]
    while {1} {
	if [eof $fd] {
	    return 0
	}
	set line [gets $fd]
	if {[string index [string trim $line 0] 0] != "#"} {
	    break
	}
    }
    set data $line[read $fd]
    close $fd
    set script [lindex $data $scriptidx]
    set help [lindex $data $helpidx]
    if {$script == ""} {
	return 0
    }
    namespace eval $namespace $script
    foreach {name value} $help {
	set helptext($name) $value
    }
    ${namespace}::init
    return 1
}

proc unload_extension {name} {
    global loaded_exts
    set name [string tolower $name]
    set count 0
    foreach ext [array names loaded_exts [string tolower $name]] {
	set namespace $ext
	catch {
	    ${namespace}::unload
	}
	# or print an error ?
	namespace delete $namespace
	incr count
	unset loaded_exts($ext)
    }
    if !$count {
	putcmsg extension_not_loaded n $name
    }    
}

proc load_extension {name} {
    global extensions loaded_exts
    if ![make_extension_index] {
	return 0
    }
    foreach i [array names extensions [string tolower $name]] {
	set biggest -1
	set bext ""
	foreach ext $extensions($i) {
	    set numver [lindex $ext 2]
	    if {$numver > $biggest} {
		set bext $ext
		set biggest $numver
	    }
	}
	if [info exists loaded_exts($i)] {
	    if {[lindex $loaded_exts($i) 1] == $biggest} {
	        putcmsg extension_already_exists n $i
		continue
	    }
	}
	if [load_extension_from_file $i [lindex $bext 0] [lindex $bext 3] [lindex $bext 4]] {
	    set loaded_exts($i) [lrange $bext 1 2]
	} else {
	    putcmsg extension_error_loading n $i
	}
    }
    if ![info exists biggest] {
	putcmsg extension_no_match n $name
    }
}
