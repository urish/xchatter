# XChatter user interface/interface routines
# $Id: interface.tcl,v 1.17 2002-03-31 17:24:00 amirs Exp $

# interface generated by SpecTcl version 1.1 from /usr/home/allow/devel/tk/xchatter/xchatter.ui
#   root     is the parent window for this user interface

proc xchatter_ui {root args} {
    global version
	
    # this treats "." as a special case

    if {$root == "."} {
        set base ""
    } else {
        set base $root
    }
    
    frame $base.mainframe

    frame $base.menu \
    	-borderwidth 1 \
    	-relief raised

    menubutton $base.commandmenu \
	-menu "$base.commandmenu.m" \
	-text Commands
    catch {
	$base.commandmenu configure \
	    -font -*-Helvetica-Bold-R-Normal-*-*-140-*-*-*-*-*-*
    }

    menubutton $base.helpmenu \
	-menu "$base.helpmenu.m" \
	-text Help
    catch {
	$base.helpmenu configure \
	    -font -*-Helvetica-Bold-R-Normal-*-*-140-*-*-*-*-*-*
    }

    label $base.label#1 \
    	-relief raised \
	-text "XChatter $version"
    catch {
	$base.label#1 configure \
    	    -font -*-Helvetica-Bold-R-Normal-*-*-140-*-*-*-*-*-*
    }

    text $base.chat \
	-height 1 \
	-width 1 \
	-wrap word \
	-cursor xterm \
	-yscrollcommand "$base.scrollbar set"
    catch {
	$base.chat configure \
	    -font -*-Courier-Medium-R-Normal-*-*-120-*-*-*-*-*-*
    }

    scrollbar $base.scrollbar \
    	-command "$base.chat yview" \
	-orient v
    
    entry $base.inputbox \
    	-cursor xterm \
	-textvariable inputbox
    catch {
	$base.inputbox configure \
	    -font -*-Helvetica-Medium-R-Normal-*-*-140-*-*-*-*-*-*
    }

    listbox $base.userlist -width 0

    # Geometry management

    grid $base.mainframe -in $root	-row 100 -column 1  \
	-sticky nesw
    grid $base.menu -in $root	-row 1 -column 1  \
	-sticky new
    grid $base.commandmenu -in $base.menu	-row 1 -column 1  \
	-sticky nesw
    grid $base.helpmenu -in $base.menu	-row 1 -column 2  \
	-sticky nesw
    grid $base.label#1 -in $base.menu	-row 1 -column 4  \
	-sticky nesw
    grid $base.chat -in $base.mainframe	-row 1 -column 1  \
	-sticky nesw
    grid $base.scrollbar -in $base.mainframe	-row 1 -column 2  \
	-sticky nsw
    grid $base.inputbox -in $root	-row 200 -column 1  \
	-sticky nesw

    grid $base.userlist -in $base.mainframe -row 1 -column 3 -sticky nesw

    # Resize behavior management
    
    grid rowconfigure $base.mainframe 1 -weight 1 -minsize 157
    grid columnconfigure $base.mainframe 1 -weight 0 -minsize 435
    grid columnconfigure $base.mainframe 2 -weight 0 -minsize 2

    grid rowconfigure $base.menu 1 -weight 0 -minsize 30
    grid columnconfigure $base.menu 1 -weight 0 -minsize 30
    grid columnconfigure $base.menu 2 -weight 0 -minsize 30
    grid columnconfigure $base.menu 3 -weight 1 -minsize 30
    grid columnconfigure $base.menu 4 -weight 0 -minsize 30
    grid rowconfigure $root 1 -weight 0 -minsize 30
    grid rowconfigure $root 100 -weight 0 -minsize 30
    grid rowconfigure $root 200 -weight 0 -minsize 30
    grid columnconfigure $root 1 -weight 0 -minsize 2

    grid columnconfigure $base.mainframe 3 -minsize 40 -weight 0

    # additional interface code

    # user-input code
    bind $base.inputbox <Key-Return> user_input
    bind $base.inputbox <Control-Key-s> {insert_char \001}
    bind $base.inputbox <Control-Key-b> {insert_char \002; break}
    bind $base.inputbox <Control-Key-k> {insert_char \013; break}
    bind $base.inputbox <Key-Up> {do_history 1}
    bind $base.inputbox <Key-Down> {do_history 0}

    # make textbox read-only
    if_unix {
        bind $base.chat <Button-1> "after idle {focus $base.inputbox}"
	bind $base.inputbox <Key-KP_Enter> user_input
    }
    bind $base.chat <ButtonPress-2> {break}
    bind $base.chat <ButtonRelease-2> {break}
    if_not_unix {
	bind $base.chat <Tab> "after idle {focus $base.inputbox}; break"
    }
    bind $base.chat <Any-Key> "process_roedit_key $base.chat {%K} {%s}"
    
    # Scrolling keys definition
    bind $base.inputbox <Key-Next> [list .chat yview scroll 1 pages]
    bind $base.inputbox <Key-Prior> [list .chat yview scroll -1 pages]
    bind $base.inputbox <Shift-Next> [list .chat yview scroll 1 units]
    bind $base.inputbox <Shift-Prior> [list .chat yview scroll -1 units]
    bind $base.inputbox <Control-Next> [list .chat yview moveto 1.0]
    bind $base.inputbox <Control-Prior> [list .chat yview moveto 0.0]
    if_unix {
	bind $base.inputbox <Key-KP_Next> [list .chat yview scroll 1 pages]
        bind $base.inputbox <Key-KP_Prior> [list .chat yview scroll -1 pages]
        bind $base.inputbox <Shift-KP_Next> [list .chat yview scroll 1 units]
        bind $base.inputbox <Shift-KP_Prior> [list .chat yview scroll -1 units]
        bind $base.inputbox <Control-KP_Next> [list .chat yview moveto 1.0]
        bind $base.inputbox <Control-KP_Prior> [list .chat yview moveto 0.0]
    }

    # text styles configuration
    global blinkstate normal_text_style
    set normal_text_style normal
    $base.chat tag configure bold -relief raised -background #cecece
    $base.chat tag configure blink -fgstipple gray50
    set blinkstate 1
    timer blink_timer tcl 250 0 {switch_blink_state}

    # window manager configuration
    wm title $root "XChatter $version"
    wm minsize $root 455 200
    wm iconname $root "XChatter"
    tk appname "XChatter"
    wm iconmask $root [find_bitmap xchatter.xbm]
    wm iconbitmap $root [find_bitmap xchatter.xbm]

    # Resize behaviour settings
    grid columnconfigure $base.mainframe 1 -weight 1
    grid rowconfigure $root 100 -weight 1
    grid rowconfigure $root 200 -weight 0
    grid columnconfigure $root 1 -weight 1

    # Inputbox history initialization
    global ib_history ib_history_ptr
    set ib_history ""
    set ib_history_ptr 0
    
    # Menus
    menu $base.commandmenu.m
    $base.commandmenu.m add command -label "List" -command {user_list ""}
    $base.commandmenu.m add command -label "Clear buffer" -command clear_chat
    $base.commandmenu.m add command -label "Quit" -command user_leave

    menu $base.helpmenu.m
    $base.helpmenu.m add command -label "Show Help" -command {user_help ""}
    $base.helpmenu.m add command -label "About" -command help_about

    # Userlist
    userlist_init $base
}

proc putchat_add_log {str} {
    global logfile putchat_log_fd
    if ![info exists logfile] {
	return
    }
    if {$logfile == ""} {
	return
    }
    if {![info exists putchat_log_fd]} {
	set putchat_log_fd [open $logfile a+]
    }
    if {$str == "\n"} {
	puts $putchat_log_fd ""
	close $putchat_log_fd
	unset putchat_log_fd
	return
    }
    puts -nonewline $putchat_log_fd $str
}

proc putchat {args} {
    global normal_text_style timestamp
    if ![llength $args] {return}
    set bold 0
    set blink 0
    set ustyle 0
    set uimage 0
    set end_visible [llength [.chat bbox "end - 1 lines"]]
    if $timestamp {
	set ts "\[[clock format [clock seconds] -format "%H:%M"]\] "
	.chat insert end $ts $normal_text_style
	putchat_add_log $ts
    }
    putchat_add_log "[join $args]"
    foreach {text style} $args {
	if {[llength [set splittext [split $text "\013\002\001\006\005"]]] > 1} {
	    set ptr 0
	    set userstyle ""
	    set newlist ""
	    foreach token $splittext {
		set ch [string index $text $ptr]
		incr ptr [expr [string length $token] + 1]
		switch -exact -- $ch {
		    \001 {
			set ustyle !$ustyle
			if $ustyle {
			    set userstyle ""
		    	}
		    }
		    \002 {
			set bold !$bold
		    }
		    \005 {
			set uimage !$uimage
			if $uimage {
			    set userimage ""
			} else {
			    # flush display cache
			    if [llength $newlist] {
				eval .chat insert end $newlist
				set newlist ""
			    }
			    # display the image
			    set images [exechook user_image $userimage]
			    foreach i $images {
				.chat image create end -image $i
			    }
			}
		    }
		    \006 {
			set bold 0
			set blink 0
			set ustyle 0
			set userstyle ""
		    }
		    \013 {
			set blink !$blink
		    }
		    default {
			incr ptr -1
		    }
		}
		if $ustyle {
		    set userstyle [concat $userstyle [exechook process_style $token]]
		    continue
	        }
		if $uimage {
		    set userimage [concat $userimage $token]
		    continue
		}
		if {$token == ""} {
		    continue
		}
		set tokstyle [concat $userstyle $normal_text_style $style]
		if $bold {
		    lappend tokstyle bold
		}
		if $blink {
		    lappend tokstyle blink
		}
    		lappend newlist $token $tokstyle
	    }
	} else { 
	    lappend newlist $text [concat $normal_text_style $style]
	}
    }
    if [llength $newlist] {
        eval .chat insert end $newlist
    }
    putchat_add_log "\n"
    .chat insert end "\n"
    if $end_visible {
	.chat see end
    } else {
	process_alias screen_updated_while_scrolled [split $text]
    }
}

proc insert_char {ch} {
    .inputbox insert insert $ch
}

proc switch_blink_state {} {
    global blinkstate
    incr blinkstate
    set states "gray75 gray50 gray25 gray12 gray25 gray50 gray75 {}"
    .chat tag configure blink -fgstipple [lindex $states [expr $blinkstate % 8]]
}

proc do_history {up} {
    global ib_history_ptr ib_history inputbox
    if [string length [string trim $inputbox]] {
	if {[llength $ib_history] == $ib_history_ptr} {
	    lappend ib_history $inputbox
	} else {
	    set ib_history [lreplace $ib_history $ib_history_ptr $ib_history_ptr $inputbox]
	}
    }
    if $up {
	incr ib_history_ptr -1
	if {$ib_history_ptr < 0} {
	    set ib_history_ptr [expr [llength $ib_history] - 1]
	}
    } else {
	incr ib_history_ptr
	if {$ib_history_ptr >= [llength $ib_history]} {
	    set ib_history_ptr 0
	}
    }
    set inputbox [lindex $ib_history $ib_history_ptr]
    .inputbox icursor end
}

proc user_input {} {
    global inputbox ib_history ib_history_ptr errorInfo
    if {$inputbox == ""} {
	return
    }
    set text $inputbox
    set inputbox ""
    if {[llength $ib_history] == 20} {
	set ib_history [lrange $ib_history 1 end]
    }
    lappend ib_history $text
    set ib_history_ptr [llength $ib_history]
    if [catch {
	process_command $text
    } err] {
	putcmsg ucmd_tclerror c $text t $errorInfo
    }
}

proc process_roedit_key {widget key shift} {
    switch $key {
	Up - Down - Left - Right - Home - End - Prior - Next {
	    return
	}
	c - C {
	    if {$shift == 4} {
		return
	    }
	}
	a - A - l - L {
	    if {$shift == 4} {
	    	$widget tag add sel 1.0 end
	    }
	}
	F4 {
	    if {$shift == 16} {
		return
	    }
	}
    }
    return -code break
}

proc clear_chat {} {
   .chat delete 1.0 end
}

proc user_leave {} {
    if ![tk_dialog .dlg "Leave XChatter" "Do you realy want to leave me alone ?" questhead 1 "Yes :-(" "No way !"] {
	exit
    }
    putcmsg quit_no
}

proc help_about {} {
    global version helploaded
    if {!$helploaded} {
        tk_dialog .dlg "About XChatter" "XChatter $version by Uri Shaked (APFGroup), (C) 2000, 2001, 2002." info 0 OK
    } else {
	show_help about
    }
}

proc userlist_init {base} {
    menu $base.userlist_menu -tearoff 0
    bind $base.userlist <3> [list userlist_right_click $base %x %y]
}

proc userlist_right_click {base x y} {
    $base.userlist activate [$base.userlist nearest $y]
    $base.userlist selection clear 0 end
    $base.userlist selection set @$x,$y
    process_event userlist_menu_popup "" $base $x $y
    tk_popup $base.userlist_menu [expr [winfo rootx $base.userlist] + $x] \
				 [expr [winfo rooty $base.userlist] + $y]
}

proc userlist_menu_add {label command} {
    .userlist_menu add command -label $label -command [concat $command {[.userlist get active]}]
}

proc userlist_menu_del {label command} {
    for {set i 0} {$i <= [expr [.userlist_menu index end]]} {incr i} {
	if {$label != [.userlist_menu entrycget $i -label]} {
	    continue
	}
	if {![string match "[string trim $command]*" [.userlist_menu entrycget $i -command]]} {
	    continue
	}
	.userlist_menu delete $i
	incr i -1
    }
}

proc userlist_add {nickname} {
    global nick
    set lnickname [string tolower $nickname]
    for {set i 0} {$i < [.userlist size]} {incr i} {
        if {[string tolower [.userlist get $i]] == $lnickname} {
	    return
	}
	if {[string compare [.userlist get $i] $nickname] >= 0} {
	    break
	}
    }
    .userlist insert $i $nickname
    if ![info exists nick] {
        return
    }
    if {[string tolower $nickname] == [string tolower $nick]} {
        if {$i != [expr [.userlist size] - 1]} {
	    incr i
	}
	catch {.userlist itemconfigure $i -foreground red} err
	catch {.userlist itemconfigure $i -selectforeground red} err
    }
}

proc userlist_del {nickname} {
    set index [lsearch -exact [string tolower [.userlist get 0 end]] [string tolower $nickname]]
    if {$index >= 0} {
        .userlist del $index
    }
}
    
proc userlist_empty {} {
    .userlist del 0 end
}

