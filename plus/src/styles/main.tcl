EXTENTION styles VERSION 1.1 BUILD 2 HELP styles.hlp
# $Id: main.tcl,v 1.2 2002-03-19 10:12:55 urish Exp $

    variable stylemap
    variable nickmap
    array set stylemap {
	0	black
	1	blue
	2	green
	3	cyan
	4	red
	5	magenta
	6	yellow
	7	white
	i	italic
	s	strike
	S	superscript
	k	blink
	b	bold
	u	underline
	d	fgweak
	D	bgweak
	r	raised
	l	sunken
	g	groove
	R	ridge
	h	hidden
	a	disappearing1
	A	disappearing2
    }
    
    proc init_window {win} {
	variable windows
	variable disappearing_state
	lappend windows $win
	$win tag configure black -foreground black
	$win tag configure blue -foreground blue
	$win tag configure green -foreground green
	$win tag configure cyan -foreground cyan
	$win tag configure red -foreground red
	$win tag configure magenta -foreground purple
	$win tag configure yellow -foreground yellow
	$win tag configure white -foreground white
	$win tag configure Bblack -background black
	$win tag configure Bblue -background blue
	$win tag configure Bgreen -background green
	$win tag configure Bcyan -background cyan
	$win tag configure Bred -background red
	$win tag configure Bmagenta -background purple
	$win tag configure Byellow -background yellow
	$win tag configure Bwhite -background white
	$win tag configure underline -underline 1
	$win tag configure strike -overstrike 1
	$win tag configure fgweak -fgstipple gray50
	$win tag configure bgweak -bgstipple gray50
	$win tag configure hidden -fgstipple [find_bitmap blank.xbm]
	$win tag configure superscript -offset 8 -font "* 8"
	$win tag configure raised -relief raised -borderwidth 1
	$win tag configure sunken -relief sunken
	$win tag configure groove -relief groove
	$win tag configure ridge -relief ridge
	# elide option is available only on patched versions of tcl8.0.5
	if ![catch {
	    $win tag configure disappearing1 -elide $disappearing_state
	    $win tag configure disappearing2 -elide [expr !$disappearing_state]
	    }] {
	    if ![timer_info disappear_timer exists] {
	        timer disappear_timer tcl 500 0 "[namespace current]::disappear_timer"
	    }
	}
	for {set i 0} {$i < 8} {incr i} {
	    $win tag configure width$i -borderwidth $i
	}
    }
    
    proc init {} {
	global nick
	variable disappearing_state 0
	init_window .chat
	# check if help module is avail.
	if [llength [info commands .xchelp.help]] {
	    init_window .xchelp.help
	}
	onevent usercmd SNICK [namespace current]::ucmd_snick \
			ACTION [namespace current]::ucmd_action \
			ME [namespace current]::ucmd_action
	onevent servercmd NICK_STYLE [namespace current]::servercmd_nick_style \
	                  NICK_STYLE_SEARCH [namespace current]::servercmd_nick_style_search \
			  ACTION [namespace current]::servercmd_action
	onevent disconnected "" [namespace current]::disconnected
	onevent userglob * [namespace current]::user_glob
	onevent serverin [join [split {
	    GLOBAL @server_glob
	    NICK @server_nick
	    JOIN @server_join
	    USER @server_user
	    QUIT @server_quit
	    ERROR @server_error
	} @] [namespace current]::]
	register_msgs {
	    xcplus_snick_nick "*** Can't set nick style before a nick is set."
	}
	hook	process_style	[namespace current]::process_style
	if {[info exists nick] && [is_connected]} {
	    putsock "GCMD NICK_STYLE_SEARCH"
	}
    }
    
    proc unload {} {
	rm_timer disappear_timer
	unevent usercmd [list [namespace current]::ucmd_snick	\
			[namespace current]::ucmd_action]
	unevent servercmd [list [namespace current]::servercmd_nick_style	\
			  [namespace current]::servercmd_nick_style_search \
			  [namespace current]::servercmd_action]
	unevent userglob [namespace current]::user_glob
	unevent serverin [list [namespace current]::server_nick \
			 [namespace current]::server_glob \
			 [namespace current]::server_join \
			 [namespace current]::server_quit \
			 [namespace current]::server_user \
			 [namespace current]::server_error]
	unevent disconnected [namespace current]::disconnected
	unhook [namespace current]::process_style
	namespace delete [namespace current]
    }
    
    proc disappear_timer {} {
	variable windows
	variable disappearing_state
	set otherstate [expr !$disappearing_state]
	foreach win $windows {
	    $win tag configure disappearing2 -elide $disappearing_state
	    $win tag configure disappearing1 -elide $otherstate
	}
	set disappearing_state $otherstate
    }

    proc process_style {style} {
	variable stylemap
	set numstate 0
	set result ""
	foreach i [split $style ""] {
	    if {$i == "B"} {
		set numstate 1
	    }
	    if {$i == "W"} {
		set numstate 2
	    }
	    if [info exists stylemap($i)] {
		if {[string match {[01234567]} $i] && $numstate} {
		    if {$numstate == 1} {
			lappend result B$stylemap($i)
		    } else {
			lappend result width$i
		    }
		} else {
		    lappend result $stylemap($i)
		}
	    }
	}
	return $result
    }
    
    proc trim_style {nick} {
	set splitnick [split $nick "\013\002\001"]
	set ptr 0
	set ustyle 0
	set rnick ""
        foreach token $splitnick {
	    set ch [string index $nick $ptr]
	    incr ptr [expr [string length $token] + 1]
	    switch -exact -- $ch {
		\001 {
		    set ustyle !$ustyle
		    if $ustyle {
		        continue
		    }
		}
		default {incr ptr -1}
	    }
	    if !$ustyle {
	        append rnick $token
	    }
	}
	return $rnick
    }
    
    proc ucmd_snick {style} {
	variable nickmap
	set snick [strtok style]
	set tnick [string range [trim_style $snick] 0 16]
	if {[string length $tnick] == 1} {
	    set tnick ${tnick}_
	}
	if {$snick != ""} {
	    set nickmap($tnick) $snick
	    putsock "NICK $tnick"
	    putsock "GCMD NICK_STYLE $snick"
	}
	return 1
    }
    
    proc servercmd_nick_style {source cargs} {
	variable nickmap
	set style [strtok cargs]
	if {[trim_style $style] == $source} {
	    set nickmap($source) $style
	}
	return 1
    }

    proc servercmd_nick_style_search {source cargs} {
	global nick
	variable nickmap
	if [info exists nick] {
	    if [info exists nickmap($nick)] {
		putsock "CMD $source NICK_STYLE $nickmap($nick)"
	    }
	}
	return 1
    }

    proc servercmd_action {source cargs} {
	variable nickmap
	if [info exists nickmap($source)] {
	    putcmsg user_action n $nickmap($source)\006 t $cargs
	    return 1
	}
	return 0
    }

    proc server_glob {sargs} {
	variable nickmap
        set nick [strtok sargs]
	if [info exists nickmap($nick)] {
	    set text [strrest sargs]
	    putcmsg glob_msg n $nickmap($nick)\006 t $text
	    return 1
	}
	return 0
    }
    
    proc server_nick {sargs} {
	variable nickmap
	set oldnick [strtok sargs]
	set newnick [strtok sargs]
	if {$oldnick == $newnick} {
	    return 0
	}
	if [info exists nickmap($oldnick)] {
	    unset nickmap($oldnick)
	}
	return 0
    }
    
    proc server_join {sargs} {
	global nick
	variable nickmap
	set nnick [strtok sargs]
	if [info exists nickmap($nnick)] {
	    unset nickmap($nnick)
	}
	return 0
    }

    proc server_user {sargs} {
	putsock "GCMD NICK_STYLE_SEARCH"
	return 0
    }
    
    proc user_glob {uargs} {
	global nick
	variable nickmap
	if [info exists nick] {
	    if [info exists nickmap($nick)] {
		putcmsg sent_glob_msg n $nickmap($nick)\006 t $uargs
		putsock "GLOB $uargs"
		return 1
	    }
	}
	return 0
    }

    proc ucmd_action {uargs} {
	global nick
	variable nickmap
	if [info exists nick] {
	    if [info exists nickmap($nick)] {
		putcmsg sent_action n $nickmap($nick)\006 t $uargs
		putsock "GCMD ACTION $uargs"
	    	return 1
	    }
	}
	return 0
    }
    
    proc server_quit {sargs} {
	variable nickmap
	set nick [strtok sargs]
	if [info exists nickmap($nick)] {
	    unset nickmap($nick)
	}
	return 0
    }

    proc server_error {sargs} {
	variable nickmap
	set errornum [strtok sargs]
	if {$errornum == 106 || $errornum == 105} {
	    set nick [strtok sargs]
	    if [info exists nickmap($nick)] {
		unset nickmap($nick)
	    }
	}
	return 0
    }
    
    proc disconnected {} {
	variable nickmap
	if [info exists nickmap] {
	    unset nickmap
	}
	return 0
    }
