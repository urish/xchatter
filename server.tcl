# XChatter SERVER I/O routines
# $Id: server.tcl,v 1.1 2001-07-25 15:32:07 uri Exp $

proc server_init {} {
    # register events
    onevent serverin {
	GLOBAL	server_glob
	MSG	server_msg
	CMD	server_cmd
	GCMD	server_gcmd
	PING	server_ping
	PONG	server_pong
	JOIN	server_join
	QUIT	server_quit
	NICK	server_nick
	ADMIN	server_admin
	ERROR	server_err
	USER	server_reg
	VERSION	server_ver
	LIST	server_list
	INFO	server_info
    }
    # command events
    onevent servercmd {
    	ACTION	server_cmd_action
	VERSION? server_cmd_version
	VERSION	server_cmd_version
	!VERSION server_cmd_version_reply
	TIME?	server_cmd_time
	TIME	server_cmd_time
	!TIME	server_cmd_time_reply
	BEEP	server_cmd_beep
    }
}

proc incoming {} {
    global sock errorInfo
    set haderr [catch {
	set line [split [gets $sock] " "]
	if {$line == ""} {
	    return
	}
    }]
    if {[eof $sock] || $haderr} {
	disconnect
	putcmsg disconnected
	return
    }
    set cmd [lindex $line 0]
    set args [lrange $line 1 end]
    if [catch {
	process_event serverin [string toupper $cmd] $args
    } err] {
	putcmsg server_tclerror b [join $line] t $errorInfo
    }
}

proc putsock {text {quiet 0}} {
    global sock
    if [info exists sock] {
	if [catch {puts $sock $text} err] {
	    disconnect
	    putcmsg socket_write_error t $err
	    return 0
	}
	return 1
    } else {
	if !$quiet {
	    putcmsg socket_not_conn
	}
        return 0
    }
}

proc is_connected {} {
    global sock
    return [info exists sock]
}

proc connect {server port} {
    global sock
    if {[catch {socket $server $port} sock]} {
	set err $sock
	unset sock
	return $err
    }
    fileevent $sock readable incoming
    fconfigure $sock -blocking 0 -buffering none
    process_event connected "" $sock
    return ""
}

proc disconnect {} {
    global sock
    if [info exists sock] {
	catch {fileevent $sock readable {}}
	catch {close $sock}
	unset sock
	process_event disconnected
	return 1
    } else {
	putcmsg socket_not_conn
        return 0
    }    
}

proc server_glob {sargs} {
    set nick [lindex $sargs 0]
    set text [join [lrange $sargs 1 end]]
    putcmsg glob_msg n $nick t $text
    return 1
}

proc server_msg {sargs} {
    set nick [lindex $sargs 0]
    set text [join [lrange $sargs 1 end]]
    putcmsg priv_msg n $nick t $text
    return 1
}

proc server_ping {sargs} {
    putsock "PONG [join $sargs]"
    return 1
}

proc server_pong {sargs} {
    set source [lindex $sargs 0]
    set data [join [lrange $sargs 1 end]]
    if [catch {set ptime [expr [clock seconds] - [lindex $data 0]]}] {
	putcmsg invalid_ping_reply n $source t $data
	return
    }
    putcmsg ping_reply n $source t $ptime
    return 1
}

proc server_reg {sargs} {
    global nick
    set nick [lindex $sargs 0]
    putcmsg nick_registered n $nick
    return 1
}

proc server_nick {sargs} {
    global nick
    if ![info exists nick] {
	return
    }
    set oldnick [lindex $sargs 0]
    set newnick [lindex $sargs 1]
    if {[string tolower $oldnick] == [string tolower $nick]} {
	putcmsg nick_change o $oldnick n $newnick
	set nick $newnick
    } else {
	if {$oldnick != $newnick} {
	    putcmsg user_nick_change o $oldnick n $newnick
	}
    }
    return 1
}

proc server_admin {sargs} {
    putcmsg admin_reply t [join [lrange $sargs 1 end]]
    return 1
}

proc server_join {sargs} {
    putcmsg user_join n [lindex $sargs 0]
    return 1
}

proc server_quit {sargs} {
    putcmsg user_quit n [lindex $sargs 0] t [join [lrange $sargs 1 end]]
    return 1
}

proc server_err {sargs} {
    if [process_alias [list onError[lindex $sargs 0]] [lrange $sargs 1 end]] {
        return
    }
    putcmsg server_error d [lindex $sargs 0] t [join [lrange $sargs 1 end]]
    return 1
}

proc server_ver {sargs} {
    putcmsg server_version_reply t [join $sargs]
    return 1
}

proc server_list {sargs} {
    global slist
    if ![info exists slist] {
	putcmsg user_list_start
	set slist 0
    }
    if {[string toupper $sargs] == "END"} {
	putcmsg user_list_end d $slist
	unset slist
	return
    }
    set user [lindex $sargs 0]
    set ipp  [lsearch $sargs IP]
    if {$ipp != -1} {
	set ip [lindex $sargs [expr $ipp + 1]]
    } else {
	set ip ""
    }
    putcmsg user_list_entry n $user i $ip
    incr slist
    return 1
}

proc server_info {sargs} {
    set user [lindex $sargs 1]
    set ip   [lindex $sargs 3]
    set idle [lindex $sargs 5]
    set conn [lindex $sargs 7]
    putcmsg user_info n $user i $ip l [duration $idle] s [clock format $conn]
    return 1
}

proc server_cmd {sargs} {
    set nick [lindex $sargs 0]
    set cmd [lindex $sargs 1]
    set args [lrange $sargs 2 end]
    process_event servercmd [string toupper $cmd] $nick $args
    return 1
}

proc server_gcmd {sargs} {
    server_cmd $sargs
    return 1
}

proc server_cmd_action {source cargs} {
    putcmsg user_action n $source t [join $cargs]
    return 1
}

proc server_cmd_version {source cargs} {
    global tcl_platform version
    if [llength $cargs] {
	return [server_cmd_version_reply $source $cargs]
    }
    putsock "CMD $source !VERSION XChatter $version by Uri Shaked, running on $tcl_platform(os) $tcl_platform(osVersion)."
    putcmsg user_requested_version n $source
    return 1
}

proc server_cmd_version_reply {source cargs} {
    putcmsg version_reply n $source t [join $cargs]
    return 1
}

proc server_cmd_time {source cargs} {
    if [llength $cargs] {
	return [server_cmd_time_reply $source $cargs]
    }
    putsock "CMD $source !TIME [clock seconds]"
    putcmsg user_requested_time n $source
    return 1
}

proc server_cmd_time_reply {source cargs} {
    if [catch {set time [clock format [lindex $cargs 0]]}] {
	putcmsg invalid_time_reply n $source
	return
    }
    putcmsg time_reply n $source t [join $time]
}

proc server_cmd_beep {source cargs} {
    putcmsg user_beep n $source t [join $cargs]
    process_alias onbeep "$source $cargs"
    return 0
}
