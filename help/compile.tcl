#! /usr/local/bin/tclsh8.0
# XChatter help compiler v1.0
# $Id: compile.tcl,v 1.5 2001-10-07 12:16:45 urish Exp $

proc replace_entities {text} {
    set first 1
    set output ""
    foreach l [split $text "&"] {
	if $first {
	    if {[string index $text 0] != "&"} {
		set first 0
		append output $l
		continue
	    }
    	}
	set p [string first ";" $l]
	if {$p == -1} {
	    if {$first} {
		append output $l
		set first 0
	    } else {
		append output "&$l"
	    }
	    continue
    	}
	set first 0
	set ap [string range $l [expr $p + 1] end]
	set bp [string range $l 0 [expr $p - 1]]
	switch -- $bp {
	    amp	{
		append output &
	    }
	    nbsp {
		append output " "
	    }
	    gt {
		append output ">"
	    }
	    lt {
		append output "<"
	    }
	    default {
		append output "&$l"
		continue
	    }
    	}
	append output $ap
    }
    return $output
}

proc process_text {text} {
    global tags help
    set topic $tags(topic)
    if {$text == ""} {
	return
    }
    set stylelist ""
    set iscenter 0
    foreach i [array names tags styles,*] {
	set style [lindex [split $i ,] 1]
	if {$tags($i) > 0} {
	    if {$style == "bold"} {
		lappend font(bold) 1
	    } elseif {$style == "italic"} {
		lappend font(italic) 1
	    } elseif {$style != "pre"} {
		lappend stylelist $style
	    }
	    if {$i == "center"} {
		set iscenter 1
	    }
	}
    }
    set link [lindex $tags(link) end]
    if {$link != ""} {
	lappend stylelist "link-$tags(link)"
    }
    foreach i $tags(font) {
	set name [lindex $i 0]
	set size [lindex $i 1]
	set color [lindex $i 2]
	set style [lindex $i 3]
	if {$name != ""} {
	    set font(name) $name
	}
	if {$color != ""} {
	    set font(color) $color
	}
	if {$style != ""} {
	    set font(style) $style
        }
	if {$size != ""} {
	    set font(size) $size
	}
    }
    if [info exists font(color)] {
	lappend stylelist color-$font(color)
    }
    if [info exists font(style)] {
	lappend stylelist style-$font(style)
    }
    if [info exists font(size)] {
        lappend fontoptions -size $font(size)
    }
    if [info exists font(name)] {
        lappend fontoptions -family $font(name)
    }
    if [info exists font(bold)] {
        lappend fontoptions -weight bold
    }
    if [info exists font(italic)] {
        lappend fontoptions -slant italic
    }
    if [info exists fontoptions] {
	lappend stylelist font-$fontoptions
    }
    if {$iscenter && !$tags(lastisnl) && [string index [string trim $text " \t"] 0] != "\n"} {
	set text \n$text
    }
    if {$tags(lastisnl) || [string index [string trim $text " \t"] 0] == "\n"} {
	set text [string trimleft $text " \t"]
    }
    set tags(lastisnl) [string match "*\n" [string trim $text]]
    if $tags(lastisnl) {
	set text [string trimright $text " \t"]
    }
    lappend help($topic) $stylelist [replace_entities $text]
}

proc argtok {var} {
    upvar $var tag
    set equal [split [join $tag " "] =]
    if {[llength [split [string trim [lindex $equal 0]]]] != 1} {
	set ret [lindex $tag 0]
	set tag [lrange $tag 1 end]
	return [list $ret]
    } else {
	set ret [string trim [lindex $equal 0]]
	set val [split [string trim [join [lrange $equal 1 end] =]] \"]
	if {[lindex $val 0] == ""} {
	    set tag [split [join [lrange $val 2 end] \"]]
	    set val [lindex $val 1]
	    return [list $ret $val]
	} else {
	    set val [split [join $val \"]]
	    set tag [lrange $val 1 end]
	    return [list $ret [lindex $val 0]]
	}
    }
}

proc splitargs {tagargs} {
    set tagargs [string trim $tagargs]
    set result ""
    while {$tagargs != ""} {
	eval lappend result [argtok tagargs]
    }
    return $result
}

proc process_tag_xchelp {closer targs} {
    global tags help
    if {$closer} {
	set tags(topic) ""
	return
    }
    foreach {name value} [splitargs $targs] {
	switch -exact -- [string tolower $name] {
	    topic {
		set tags(topic) [string tolower $value]
	    }
	    alias {
		lappend aliases $value
	    }
	    aliases {
		eval lappend aliases [split $value ","]
	    }
    	}
    }
    if [info exists aliases] {
	foreach i $aliases {
	    set help($i) "@$tags(topic)"
        }
    }
}

proc process_tag_style {closer style} {
    global tags
    set add [expr $closer ? -1 : 1]
    incr tags(styles,$style) $add
}

proc process_tag_font {closer targs} {
    global tags
    if $closer {
	set tags(font) [lrange $tags(font) 0 [expr [llength $tags(font)] - 2]]
	return
    }
    set fontname ""
    set style ""
    set size ""
    set color ""
    foreach {name value} [splitargs $targs] {
	switch -exact -- [string tolower $name] {
	    style {
		set style $value
	    }
	    name {
		set fontname $value
	    }
	    size {
		if [catch {expr $value > 0 && $value < 256} result] {
		    continue
		}
		if $result {
		    set size $value
		}
	    }
	    color {
		set color $value
	    }
	}
    }
    lappend tags(font) [list $fontname $size $color $style]
}

proc process_tag_link {closer targs} {
    global tags
    if $closer {
	set tags(link) [lrange $tags(link) 0 [expr [llength $tags(link)] - 2]]
	return
    }
    foreach {name value} [splitargs $targs] {
	switch -exact -- [string tolower $name] {
	    topic {
		set topic $value
	    }
	}
    }
    lappend tags(link) $topic
}

proc process_tag {tag} {
    set tag [split $tag]
    set cmd [lindex $tag 0]
    set args [lrange $tag 1 end]
    set closer 0
    if {[string index $cmd 0] == "/"} {
	set closer 1
	set cmd [string range $cmd 1 end]
    }
    switch -glob -- [string toupper $cmd] {
	!--* {
	    return
	}
	XCHELP {
	    process_tag_xchelp $closer $args
	}
	CENTER {
	    process_tag_style $closer center
	}
	U {
	    process_tag_style $closer underline
	}
	B {
	    process_tag_style $closer bold
	}
	I {
	    process_tag_style $closer italic
	}
	PRE {
	    process_tag_style $closer pre
	}
	FONT {
	    process_tag_font $closer $args
	}
	LINK {
	    process_tag_link $closer $args
	}
	default {
	    puts "Unknown Tag: $tag"
	}
    }
}

proc process_file {fname} {
    global tags result
    set data [read [open $fname]]
    set state 0
    foreach ch [split $data ""] {
	switch $state {
	    0 {
		if {$ch == "<"} {
		    set state 1
		    set tagdata ""
		} elseif {$ch == "\n" && $tags(styles,pre) < 1} {
		    if {$result != ""} {
		        append result " "
		    }
		} else {
		    append result $ch
		}
	    }
	    1 {
		if {$ch == ">"} {
		    if {[string index $tagdata 0] == "."} {
			append result "<[string range $tagdata 1 end]>"
		    } elseif {[string tolower [lindex [split $tagdata] 0]] == "br"} {
			append result \n
		    } else {
			process_text $result
			process_tag $tagdata
			set result ""
		    }
		    set state 0
		} elseif {$ch == {"}} {
		    set state 2
		    append tagdata {"}
		} else {
		    append tagdata $ch
		}
	    }
	    2 {
		append tagdata $ch
		if {$ch == {\\}} {
		    set state 3
		} elseif {$ch == {"}} {
		    set state 1
		}
	    }
	    3 {
		append tagdata $ch
		set state 2
	    }
	}
    }
}

proc init_tags {} {
    global tags result
    set result ""
    set tags(topic) ""
    set tags(styles,center) 0
    set tags(styles,underline) 0
    set tags(styles,bold) 0
    set tags(styles,italic) 0
    set tags(styles,pre) 0
    set tags(lastisnl) 1
    set tags(font) ""
    set tags(link) ""
}

proc find_help_files {dir} {
    global helpfiles
    foreach i [glob -nocomplain $dir/*] {
	if [file isdirectory $i] {
	    find_help_files $i
	} elseif [string match "*.hlp" $i] {
	    lappend helpfiles $i
	}
    }
}

if [info exists no_standalone] {
    return
}

puts "Compiling help files, please hold on..."
find_help_files .
foreach i $helpfiles {
    puts "* $i"
    init_tags
    process_file $i
}

set output [open ../xchatter.hlp w+]
puts $output [array get help]
close $output
