# XChatter's online help system
# $Id: help.tcl,v 1.1 2001-07-25 15:32:06 uri Exp $

proc init_help {} {
    global helptext
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
    wm protocol .xchelp WM_DELETE_WINDOW {wm withdraw .xchelp}
    frame .xchelp.menu -relief raised
    button .xchelp.menu.prevbutton -text "Previous" -command "show_help_prev" -cursor hand2
    button .xchelp.menu.indexbutton -text "Index" -command "show_help index" -padx 2 -cursor hand2
    button .xchelp.menu.closebutton -text "Close" -command "wm withdraw .xchelp" -padx 2 -cursor hand2
    scrollbar .xchelp.scrollbar -command ".xchelp.help yview"
    pack .xchelp.menu -fill both -side top
    pack .xchelp.menu.prevbutton -fill y -side left
    pack .xchelp.menu.indexbutton -fill y -side left
    pack .xchelp.menu.closebutton -fill y -side left
    pack .xchelp.scrollbar -fill y -side right -anchor ne
    pack .xchelp.help -fill both -expand yes -side left -padx 2 -anchor nw -before .xchelp.scrollbar
    set helptext(unknown) "{} {Error: No help file loaded.}"
    catch {
	set helpfile [open xchatter.hlp r]
	array set helptext [read $helpfile]
	close $helpfile
    }
}

proc show_help {topic} {
    global helptext helptopics
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
    foreach {style text} $helptext($topic) {
	set styles ""
	foreach i $style {
	    set j [split $i -]
	    switch -- [lindex $j 0] {
		font {
		    catch {.xchelp.help tag configure $i -font [join [lrange $j 1 end] -]}
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
