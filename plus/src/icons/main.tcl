EXTENTION icons VERSION 1.1 BUILD 1
# $Id: main.tcl,v 1.2 2002-03-19 10:21:47 urish Exp $

<@INCLUDE icons.tcl>

proc init {} {
    hook user_image	[namespace current]::user_image
    bind .inputbox <Control-Key-i>	[namespace current]::ctrl_i_pressed
    frame .icon_select -background [.inputbox cget -background] -relief raised -width 2
    set j 0
    foreach i [image names] {
	set lname .icon_select.l$j
	label $lname -image $i -background [.icon_select cget -background]
	bind $lname <1> [list [namespace current]::insert_icon [namespace tail $i]]
	pack $lname -side left
	incr j
    }
    grid .icon_select -in . -row 180 -column 1 -sticky nesw
}

proc unload {} {
    unhook user_image	[namespace current]::user_image
    bind .inputbox <Control-Key-i>	""
    destroy .icon_select
}

proc ctrl_i_pressed {} {
    insert_char \005
}

proc image_exists {img} {
    return [expr ![catch {image type $img}]]
}

proc user_image {names} {
    set result ""
    foreach name [split $names :] {
	if [string match {[123456789]\**} $name] {
	    set count [string index $name 0]
	    set name [string range $name 2 end]
	} else {
	    set count 1
	}
	set name [namespace current]::icons::[string tolower [string trim $name]]
	if ![image_exists $name] {
	    continue
	}
	for {set i 0} {$i < $count} {incr i} {
	    lappend result $name
	}
    }
    return $result
}

proc insert_icon {name} {
    insert_char \005$name\005
}
