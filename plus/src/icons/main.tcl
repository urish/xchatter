EXTENTION icons VERSION 1.1 BUILD 1
# $Id: main.tcl,v 1.1 2002-03-16 10:54:26 urish Exp $

<@INCLUDE icons.tcl>

proc init {} {
    hook	user_image	[namespace current]::user_image
    bind .inputbox <Control-Key-i>	[namespace current]::ctrl_i_pressed
}

proc ctrl_i_pressed {} {
    global inputbox
    set count 0
    foreach i [split $inputbox ""] {
	if {$i == "\005"} {
	    incr count
	}
    }
    insert_char \005
    if {$count % 2} {
	catch {
	    destroy .icon_select
	}
	return
    }
    catch {
	toplevel .icon_select
    }
    raise .icon_select
    focus .inputbox
    set j 0
    foreach i [image names] {
	set lname .icon_select.l$j
	label $lname -image $i
	bind $lname <1> [list insert_char [namespace tail $i]\005]
	bind $lname <1> "+destroy .icon_select"
	pack $lname
	incr j
    }
}

proc image_exists {img} {
    return [expr ![catch {image type $img}]]
}

proc user_image {names} {
    set result ""
    foreach name [split $names :] {
	set name [namespace current]::icons::[string tolower [string trim $name]]
	if ![image_exists $name] {
	    continue
	}
	lappend result $name
    }
    return $result
}
