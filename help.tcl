# XChatter's online help system
# $Id: help.tcl,v 1.3 2001-08-25 11:36:23 urish Exp $

proc init_help {} {
    global helptext helpfont
    toplevel .xchelp
    wm title .xchelp "XChatter's online help"
    wm withdraw .xchelp
    text .xchelp.help -yscrollcommand ".xchelp.scrollbar set" -wrap word
    if_unix {
	.xchelp.help configure -cursor gumby
    }
    bind .xchelp.help <Any-Key> {process_roedit_key .xchelp.help {%K} {%s}}
    bind .xchelp.help <ButtonPress-2> {break}
    bind .xchelp.help <ButtonRelease-2> {break}
    .xchelp.help tag configure center -justify center
    .xchelp.help tag configure underline -underline 1
    .xchelp.help tag configure link -underline 1 -foreground blue
    .xchelp.help tag bind link <Any-Enter> help_link_enter
    .xchelp.help tag bind link <Any-Leave> help_link_leave
    wm protocol .xchelp WM_DELETE_WINDOW {help_hide}
    frame .xchelp.menu -relief raised
    button .xchelp.menu.prevbutton -text "Previous" -command "show_help_prev" -cursor hand2
    button .xchelp.menu.indexbutton -text "Index" -command "show_help index" -padx 2 -cursor hand2
    button .xchelp.menu.closebutton -text "Close" -command "help_hide" -padx 2 -cursor hand2
    button .xchelp.menu.fontbutton -text "Font..." -command "help_set_font .xchelp.fontsel" -padx 2 -cursor hand2
    scrollbar .xchelp.scrollbar -command ".xchelp.help yview"
    pack .xchelp.menu -fill both -side top
    pack .xchelp.menu.prevbutton -fill y -side left
    pack .xchelp.menu.indexbutton -fill y -side left
    pack .xchelp.menu.closebutton -fill y -side left
    pack .xchelp.menu.fontbutton -fill y -side left
    pack .xchelp.scrollbar -fill y -side right -anchor ne
    pack .xchelp.help -fill both -expand yes -side left -padx 2 -anchor nw -before .xchelp.scrollbar
    set helptext(unknown) "{} {Error: No help file loaded.}"
    set helpfont [font actual default]
    catch {
	set helpfile [open xchatter.hlp r]
	array set helptext [read $helpfile]
	close $helpfile
    }
}

proc show_help {topic} {
    global helptext helpfont helptopics
    if {[string trim $topic] == ""} {
	set topic index
    }
    wm deiconify .xchelp
    focus .xchelp
    .xchelp.help del 1.0 end
    if ![info exists helptext($topic)] {
	if [info exists helptext(cmd_$topic)] {
	    set topic cmd_$topic
	} else {
	    set topic unknown
	}
    }
    lappend helptopics $topic
    .xchelp.help tag configure default -font $helpfont
    foreach {style text} $helptext($topic) {
	set styles "default"
	foreach i $style {
	    set j [split $i -]
	    switch -- [lindex $j 0] {
		font {
		    catch {.xchelp.help tag configure $i -font [concat $helpfont [join [lrange $j 1 end] -]]}
		}
		color {
		    catch {.xchelp.help tag configure $i -foreground [lindex $j 1]}
		}
		link {
		    .xchelp.help tag bind $i <Button-1> "show_help [lindex $j 1]"
		    lappend styles link
		}
	    }
	    lappend styles $i
	}
	.xchelp.help insert end $text $styles
	.xchelp.help see 1.0
    }
}

proc show_help_refresh {} {
    global helptopics
    set topic [lindex $helptopics end]
    set helptopics [lrange $helptopics 0 [expr [llength $helptopics] - 1]]
    show_help $topic
}

proc show_help_prev {} {
    global helptopics
    set lasttopic [lindex $helptopics [expr [llength $helptopics] - 2]]
    if {$lasttopic != ""} {
	show_help $lasttopic
        set helptopics [lrange $helptopics 0 [expr [llength $helptopics] - 3]]
    }
}

proc help_link_enter {} {
    .xchelp.help configure -cursor hand2
}

proc help_link_leave {} {
    .xchelp.help configure -cursor ""
    if_unix {
	.xchelp.help configure -cursor gumby
    }
}

proc help_hide {} {
    wm withdraw .xchelp
    catch {
	destroy .xchelp.fontsel
    }
}

# Font selection dialog
proc help_set_font {base} {
    global help_original_font helpfont help_font_size
    if [llength [info commands $base]] {
	raise $base
	focus $base
	return
    }
    set help_original_font $helpfont
    set fspos [lsearch $helpfont "-size"]
    set ffpos [lsearch $helpfont "-family"]
    if {$fspos != -1} {
	set help_font_size [lindex $helpfont [expr $fspos + 1]]
    } else {
	set help_font_size 12
    }
    set families [lsort [font families]]
    set family 0
    if {$ffpos != -1} {
	set familyname [lindex $helpfont [expr $ffpos + 1]]
	set family [lsearch $families $familyname]
	if {$family == -1} {
	    set family 0
	}
    }
    toplevel $base
    wm title $base "Default help font selection"
    frame $base.fontopts -relief raised
    frame $base.family -relief raised
    frame $base.size -relief raised
    frame $base.buttons -relief raised
    label $base.family.label -text "Family:"
    listbox $base.family.list -yscrollcommand "$base.family.scroll set" -width 0
    scrollbar $base.family.scroll -command "$base.family.list yview"
    label $base.size.label -text "Size:"
    scale $base.size.scale -showvalue 1 -from 8 -to 72 -variable help_font_size -orient vertical
    button $base.buttons.ok -text "Ok" -command "help_set_font_ok $base"
    button $base.buttons.cancel -text "Cancel" -command "help_set_font_cancel $base"
    button $base.buttons.apply -text "Apply" -command "help_set_font_apply $base"
    pack $base.fontopts
    eval $base.family.list insert end $families
    $base.family.list selection anchor $family
    $base.family.list selection set $family
    $base.family.list see $family
    pack $base.family -in $base.fontopts -side left
    pack $base.family.label -anchor w
    pack $base.family.list -side left
    pack $base.family.scroll -side left -fill y
    pack $base.size -in $base.fontopts -side left -anchor n
    pack $base.size.label -anchor w
    pack $base.size.scale -fill y
    pack $base.buttons.ok -side left
    pack $base.buttons.cancel -side left
    pack $base.buttons.apply -side left
    pack $base.buttons
}

proc help_set_font_ok {base} {
    global helpfont help_font_size
    set helpfont [list -family [$base.family.list get anchor] -size $help_font_size]
    show_help_refresh
    destroy $base
}

proc help_set_font_cancel {base} {
    global helpfont help_original_font
    if {$helpfont != $help_original_font} {
	set helpfont $help_original_font
        show_help_refresh
    }
    destroy $base
}

proc help_set_font_apply {base} {
    global helpfont help_font_size
    set helpfont [list -family [$base.family.list get anchor] -size $help_font_size]
    show_help_refresh
    focus $base
}
