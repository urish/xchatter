#! /bin/sh
# the next line restarts using wish8.0 \
exec wish8.0 "$0" "$@"; exit
# XChatter's main source file
# $Id: xchatter.tcl,v 1.1 2001-07-25 15:32:07 uri Exp $

set version 0.5
set numver 50.0

# Multi language support
proc format_msg {msg args} {
    global text
    if ![info exists text] {
	set arglist ""
	foreach {i j} $args {
	    lappend arglist "%$i='$j'"
	}
	return "(format_msg) $msg ARGS [join $arglist ", "]"
    }
    if ![info exists text($msg)] {
	return ""
    }
    foreach {i j} $args {
	lappend switch_args $i "append output [list $j]"
    }
    lappend switch_args % {append output %} default {append output %$buf}
    set msg $text($msg)
    set output ""
    while {[set i [string first "%" $msg]] > -1} {
	append output [string range $msg 0 [expr $i - 1]]
	set buf [string index $msg [expr $i + 1]]
	set msg [string range $msg [expr $i + 2] end]
	switch -glob -- $buf $switch_args
    }
    return $output$msg
}

proc putcmsg {msg args} {
    set fmsg [eval format_msg $msg $args]
    foreach i [split $fmsg \n] {
        putchat $i
    }
}

proc register_msgs {args} {
    global text
    set found 0
    if {[llength $args] == 1} {
	set args [lindex $args 0]
    } elseif {[llength $args] % 2} {
	error "list must have an even number of elements"
    }
    foreach {msg txt} $args {
	if [info exists text($msg)] {
	    continue
	}
	set text($msg) $txt
    }
    return $found
}

# Events for plugins
proc update_events {} {
    global events _events
    foreach event [lsort [array names _events]] {
	catch {unset e}
	foreach {mask proc} $_events($event) {
	    lappend e($mask) $proc
	}
	set events($event) ""
	foreach mask [array names e] {
	    lappend events($event) $mask
	    set script ""
	    foreach proc $e($mask) {
		if {$proc == ""} {
		    append script {return 1;}
		    break
		}
    		append script [format {
		    if {[eval %s $args] == "1"} {
			return 1
		    }
		} $proc]
	    }
	    lappend events($event) $script
	}
    }
}

proc onevent {event args} {
    global _events
    switch [llength $args] {
	0 {
	    return 0
	}
	1 {
	    set a [lindex $args 0]
	}
	default {
	    set a $args
	}
    }
    if {[llength $a] % 2} {
	error "list must have an even number of elements"
    }
    if ![info exists _events($event)] {
	set _events($event) ""
    }
    foreach {mask proc} $a {
	set _events($event) [concat [list $mask $proc] $_events($event)]
    }
    update_events
    return 1
}

proc unevent {event proclist} {
    global _events
    if ![info exists _events($event)] {
	return 0
    }
    set result ""
    set found 0
    foreach {emask eproc} $_events($event) {
	set eq 0
	foreach proc $proclist {
	    if [string match $proc $eproc] {
		set eq 1
	    }
	}
	if !$eq {
	    lappend result $emask $eproc
	} else {
	    incr found
	}
    }
    if {$found} {
	set _events($event) $result
	update_events
	return $found
    }
    return 0
}

proc process_event {event {string ""} args} {
    global events
    if [info exists events($event)] {
	switch -glob -- $string $events($event)
    }
    return 0
}

# hook system for plugins
proc hook {args} {
    global hooks
    if {[llength $args] == 1} {
	set args [lindex $args 0]
    }
    if {[llength $args] % 2} {
	error "list must have an even number of elements"
    }
    foreach {hook proc} $args {
	lappend hooks($hook) $proc
    }
}

proc unhook {args} {
    global hooks
    foreach proc $args {
	foreach {hook procs} [array get hooks] {
	    if {[set i [lsearch -exact $procs $proc]]} {
		set hooks($hook) [lreplace $procs $i $i]
		if ![llength $hooks($hook)] {
		    unset hooks($hook)
		    continue
		}
	    }
	}
    }
}

proc exechook {hook args} {
    global hooks
    if ![info exists hooks($hook)] {
	return ""
    }
    eval [lindex $hooks($hook) 0] $args
}

# Skins
proc load_skin {fname} {
    global text
    if ![file readable $fname] {
	putcmsg skin_not_found t $fname
	return 0
    }
    set skin [open $fname r]
    set skindata [split [read $skin] \n]
    close $skin
    set c 0
    foreach i $skindata {
	incr c
	set i [split [string trim $i]]
	if {[string index $i 0] == "#" || $i == ""} continue
	set cmd [string toupper [lindex $i 0]]
	set args [split [string trim [join [lrange $i 1 end]]]]
	switch -glob -- $cmd {
	STYLE {
	    set name .[lindex [split [lindex $args 0] :] 0]
            set tagname [lindex [split [lindex $args 0] :] 1]
	    set args [split [string trim [join [lrange $args 1 end]]]]
            set fargs ""
            foreach {j k} $args {
                append fargs "-$j $k "
    	    }
            if [catch "$name tag configure $tagname [string trim $fargs]"] {
		putcmsg skin_error d $c
	    }
	}
	NORM_TEXT_STYLE {
	    global normal_text_style
	    set normal_text_style [string trim [join $args]]
	}
	PRINT {
	    putcmsg skin_print t [string trim [join $args]]
	}
	ITEM {
	    set name ".[join [split [lindex $args 0] :] .]"
	    set args [split [string trim [join [lrange $args 1 end]]]]
            set fargs ""
            foreach {j k} $args {
                append fargs "-$j $k "
    	    }
    	    if [catch "$name configure [string trim $fargs]"] {
		putcmsg skin_error d $c
	    }
	}
	TCL {
	    if [catch [join $args] err] {
		putcmsg skin_tcl_error d $c t $err
            } else {
		putcmsg skin_tcl_warning d $c t [join [lrange $i 1 end]]
            }
	}
	TEXT {
	    if {$args == ""} continue
	    set append 0
	    set name [lindex $args 0]
	    if {[string index $name 0] == "+"} {
		set name [string range $name 1 end]
		set append 1
	    }
	    set value [string trim [join [lrange $args 1 end]]]
	    if {[string index $value 0] == "|"} {
		set value [string range $args 1 end]
	    }
	    if $append {
		append text($name) "\n$value"
	    } else {
		set text($name) $value
	    }
	}
	default {
	    putcmsg skin_invalid_cmd d $c t $cmd
            return    
	}
	}
    }
}

# String/argument processing routines
proc strtok {varname} {
    upvar $varname args
    set args [split [string trim [join $args]]]
    set ret [lindex $args 0]
    set args [lrange $args 1 end]
    return $ret
}

proc strrest {varname} {
    upvar $varname args
    return [string trim [join $args]]
}

# Time routines
proc duration {time} {
        set years [expr $time / 31449600]
        set weeks [expr $time % 31449600 / 604800]
        set days [expr $time % 604800 / 86400]
        set hours [expr $time % 86400 / 3600]
        set minutes [expr $time % 3600 / 60]
        set seconds [expr $time % 60]
        if {$years != 0} {return "$years years, $weeks weeks, $days days, $hours hours, $minutes mins, $seconds secs" }
        if {$weeks != 0} {return "$weeks weeks, $days days, $hours hours, $minutes mins, $seconds secs" }
        if {$days != 0} {return "$days days, $hours hours, $minutes mins, $seconds secs" }
        if {$hours != 0} {return "$hours hours, $minutes mins, $seconds secs" }
        if {$minutes != 0} {return "$minutes mins, $seconds secs" }
        return "$seconds secs"
}

# Misc routines
proc if_unix {script} {
    global tcl_platform
    if {$tcl_platform(platform) == "unix"} {
	uplevel $script
    }
}

proc find_bitmap {name} {
    foreach i {./ {} bitmaps/} {
	if [file readable $i$name] {
	    return @$i$name
	}
    }
    return ""
}

# Change directory
catch {
    if {[set last [string last / [info script]]] != -1} {
	cd [string range [info script] 0 [expr $last - 1]]
    }
}

# Load other source files
source server.tcl
source usercmd.tcl
source interface.tcl
source help.tcl

# Initialize graphical user interface
xchatter_ui .

# A security fix - forbids the 'send' command.
catch {
    rename send {}
}

# Load help
init_help

# Initialize user command interface, server interface
usercmd_init
server_init

# Set some defaults
set timestamp 1

# Load messages file
if [file readable lang/english.lang] {
    load_skin lang/english.lang
} else {
    putchat "*** Warning: no language file found, use /skin <filename> to load messages."
}

# Initialize aliases, plugins...
global aliases aliaslevel plugins
set aliases ""
set aliaslevel 0
set plugins ""

putcmsg welcome t $version

set rcread 0
if [file readable xchatter.rc] {
    putcmsg xchatter_rc
    set fidx [open xchatter.rc]
    set buf [read $fidx]
    close $fidx
    process_command $buf
    incr rcread
}

if [file readable ~/.xchatterrc] {
    putcmsg home_xchatter_rc
    set fidx [open ~/.xchatterrc]
    set buf [read $fidx]
    close $fidx
    process_command $buf
    incr rcread
}

if !$rcread {
    process_command [join [split {
	/alias onbeep /bell
	/alias onError106 /nick $0_
	/alias +onError106 /echo *** Nick $0 is already in use; using $0_.
	/;} \t] ""]
}
