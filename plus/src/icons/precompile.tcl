# extension precompile - build icons into icons.tcl

# following functions were ripped off base64.tcl from tcllib.
# They were coded by Stephen Uhler / Brent Welch (c) 1997 Sun Microsystems
# and Copyright (c) 1998-2000 by Ajuba Solutions.
proc base64_prepare {} {
    global base64_en
    set i 0
    foreach char {A B C D E F G H I J K L M N O P Q R S T U V W X Y Z \
		a b c d e f g h i j k l m n o p q r s t u v w x y z \
		0 1 2 3 4 5 6 7 8 9 + /} {
        lappend base64_en $char
    }
}

proc base64_encode {args} {
    global base64_en	
    # Set the default wrapchar and maximum line length to match the output
    # of GNU uuencode 4.2.  Various RFC's allow for different wrapping 
    # characters and wraplengths, so these may be overridden by command line
    # options.
    set wrapchar "\n"
    set maxlen 60
    
    if { [llength $args] == 0 } {
        error "wrong # args: should be \"[lindex [info level 0] 0]\
	    ?-maxlen maxlen? ?-wrapchar wrapchar? string\""
    }

    set optionStrings [list "-maxlen" "-wrapchar"]
    for {set i 0} {$i < [llength $args] - 1} {incr i} {
        set arg [lindex $args $i]
        set index [lsearch -glob $optionStrings "${arg}*"]
        if { $index == -1 } {
	    error "unknown option \"$arg\": must be -maxlen or -wrapchar"
	}
	incr i
	if { $i >= [llength $args] - 1 } {
	    error "value for \"$arg\" missing"
	}
	set val [lindex $args $i]

        # The name of the variable to assign the value to is extracted
	# from the list of known options, all of which have an
	# associated variable of the same name as the option without
	# a leading "-". The [string range] command is used to strip
	# of the leading "-" from the name of the option.
	#
	# FRINK: nocheck
	set [string range [lindex $optionStrings $index] 1 end] $val
    }
    
    # [string is] requires Tcl8.2; this works with 8.0 too
    if {[catch {expr {$maxlen % 2}}]} {
        error "expected integer but got \"$maxlen\""
    }

    set string [lindex $args end]

    set result {}
    set state 0
    set length 0

    # Process the input bytes 3-by-3

    binary scan $string c* X
    foreach {x y z} $X {
        # Do the line length check before appending so that we don't get an
        # extra newline if the output is a multiple of $maxlen chars long.
        if {$maxlen && $length >= $maxlen} {
	    append result $wrapchar
	    set length 0
	}
	
	append result [lindex $base64_en [expr {($x >>2) & 0x3F}]] 
	if {$y != {}} {
	    append result [lindex $base64_en [expr {(($x << 4) & 0x30) | (($y >> 4) & 0xF)}]] 
	    if {$z != {}} {
	        append result \
	    	    [lindex $base64_en [expr {(($y << 2) & 0x3C) | (($z >> 6) & 0x3)}]]
	        append result [lindex $base64_en [expr {($z & 0x3F)}]]
	    } else {
	        set state 2
	        break
	    }
	} else {
	    set state 1
	    break
	}
	incr length 4
    }
    if {$state == 1} {
        append result [lindex $base64_en [expr {(($x << 4) & 0x30)}]]== 
    } elseif {$state == 2} {
        append result [lindex $base64_en [expr {(($y << 2) & 0x3C)}]]=  
    }
    return $result
}



proc precompile {basedir} {
    global error
    if ![file isdirectory $basedir/icons] {
	set error "icons: no such directory."
        return 0
    }

    if ![file readable $basedir/icons/index.txt] {
        set error "Cant open icons/index.txt for writing."
        return 0
    }

    if [catch {open $basedir/icons.tcl w} fd] {
        set error "Cant open icons.tcl for writing: $fd"
        return 0
    }

    base64_prepare
    puts $fd "# ICONS compiled file. Generated at [clock format [clock seconds]]."
    puts $fd "namespace eval icons {"

    set idxfd [open $basedir/icons/index.txt]
    set idx [split [read $idxfd] \n]
    close $idxfd

    foreach line $idx {
        set name [split $line =]
        set fname [string trim [join [lrange $name 1 end] =]]
        set name [string tolower [string trim [lindex $name 0]]]
	if {$name == "" || $fname == ""} {
	    continue
	}
        if [catch {open $basedir/icons/$fname r} iconfd] {
	    puts "Warning: couldn't read icon from icons/$fname: $iconfd"
	    continue
	}
	fconfigure $iconfd -translation binary
	set edata [base64_encode -maxlen 70 -wrapchar "\n\t" [read $iconfd]]
	close $iconfd
	puts $fd "image create photo \[namespace current]::$name -data {\n\t$edata\n}"
    }

    puts $fd "}"
    close $fd
    return 1
}
    
if ![info exists basedir] {
    return 0
}

return [precompile $basedir]
