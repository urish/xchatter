# XChatter SERVER I/O routines
# $Id: server.tcl,v 1.10 2002-03-18 20:28:22 urish Exp $

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
	SINFO	server_sinfo
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
    onevent connected "" userlist_connected
    onevent disconnected "" userlist_disconnected
}

proc incoming {} {
    global sock errorInfo
    set haderr [catch {
	set line [split [gets $sock] " "]
    }]
    if {[eof $sock] || $haderr} {
	disconnect
	putcmsg disconnected
	return
    }
    if {$line == ""} {
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
    global sock server_inf
    set server_inf "$server $port"
    if {[catch {socket $server $port} sock]} {
	set err $sock
	unset sock
	return $err
    }
    fileevent $sock readable incoming
    fconfigure $sock -blocking 0 -buffering none
    process_event connected "" $sock $server $port
    process_alias onconnect "$server $port"
    return ""
}

proc disconnect {} {
    global sock server_inf
    if [info exists sock] {
	catch {fileevent $sock readable {}}
	catch {close $sock}
	unset sock
	process_event disconnected "" $server_inf
        process_alias ondisconnect $server_inf
	return 1
    } else {
	putcmsg socket_not_conn
        return 0
    }    
}

proc server_glob {sargs} {
    set nick [lindex $sargs 0]
    set text [join [lrange $sargs 1 end]]
    putcmsg glob_msg -nick $nick -type global n $nick t $text
    return 1
}

proc server_msg {sargs} {
    set nick [lindex $sargs 0]
    set text [join [lrange $sargs 1 end]]
    putcmsg priv_msg -nick $nick -type in n $nick t $text
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
	putcmsg invalid_ping_reply -nick $source -type in n $source t $data
	return
    }
    putcmsg ping_reply -nick $source -type in n $source t $ptime
    return 1
}

proc server_reg {sargs} {
    global nick
    set nick [lindex $sargs 0]
    putcmsg nick_registered n $nick
    userlist_add $nick
    return 1
}

proc server_nick {sargs} {
    global nick
    if ![info exists nick] {
	return
    }
    set oldnick [lindex $sargs 0]
    set newnick [lindex $sargs 1]
    if {$oldnick == $newnick} {
	return
    }
    userlist_del $oldnick
    userlist_add $newnick
    if {[string tolower $oldnick] == [string tolower $nick]} {
	putcmsg nick_change -nick $oldnick -type server o $oldnick n $newnick
	set nick $newnick
    } else {
        putcmsg user_nick_change o $oldnick n $newnick
    }
    return 1
}

proc server_admin {sargs} {
    putcmsg admin_reply t [join [lrange $sargs 1 end]]
    return 1
}

proc server_join {sargs} {
    putcmsg user_join -nick [lindex $sargs 0] -type server n [lindex $sargs 0]
    userlist_add [lindex $args 0]
    return 1
}

proc server_quit {sargs} {
    set user [lindex $sargs 0]
    set reason [join [lrange $sargs 1 end]]
    putcmsg user_quit -nick $user -type server n $user t $reason
    userlist_del [lindex $args 0]
    return 1
}

proc server_err {sargs} {
    if [process_alias [list onError[lindex $sargs 0]] [lrange $sargs 1 end]] {
        return
    }
    putcmsg server_error -type error d [lindex $sargs 0] t [join [lrange $sargs 1 end]]
    return 1
}

proc server_ver {sargs} {
    putcmsg server_version_reply t [join $sargs]
    return 1
}

proc server_list {sargs} {
    global slist
    if ![info exists slist] {
	putcmsg user_list_start -type list 
	userlist_empty
	set slist 0
    }
    if {$slist == "hidden1"} {
	userlist_empty
	set slist "hidden2"
    }
    if {$slist == "hidden2"} {
	if {[string toupper $sargs] == "END"} {
	  unset slist
	  return 1
	}
	userlist_add [strtok sargs]
	return 1
    }
    if {[string toupper $sargs] == "END"} {
	putcmsg user_list_end -type list d $slist
	unset slist
	return
    }
    set user [strtok sargs]
    set ip "0.0.0.0"
    while {[llength $sargs]} {
	set name [strtok sargs]
	set value [strtok sargs]
	switch -exact -- $name {
	    IP 		{ set ip	$value }
	}
    }
    putcmsg user_list_entry -type list n $user i $ip
    userlist_add $user
    incr slist
    return 1
}

proc server_info {sargs} {
    set user ""
    set ip   "0.0.0.0"
    set idle 0
    set conn 0
    while {[llength $sargs]} {
	set name [strtok sargs]
	set value [strtok sargs]
	switch -exact -- $name {
	    NICK 	{ set user 	$value }
	    IP 		{ set ip	$value }
	    IDLE 	{ set idle 	$value }
	    CONNECTED 	{ set conn 	$value }
	}
    }
    putcmsg user_info -nick $user -type info n $user i $ip l [duration $idle] s [clock format $conn]
    return 1
}

proc server_sinfo {sargs} {
    set uptime 0
    set idle 0
    set clients "?"
    set unreg "?"
    while {[llength $sargs]} {
	set name [strtok sargs]
	set value [strtok sargs]
	switch -exact -- $name {
	    CLIENTS {set clients $value}
	    UNKNOWN {set unreg $value}
	    IDLE {set idle $value}
	    UPTIME {set uptime $value}
	}
    }
    putchat "*** Server information:"
    putchat "*** $clients clients ($unreg unregistered)."
    putchat "*** Average idle time: [duration $idle]."
    putchat "*** Server uptime: [duration $uptime]."
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
    putcmsg user_action -nick $source -type global n $source t [join $cargs]
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

proc userlist_connected {sock server port} {
    global slist
    set slist hidden1
    putsock "LIST"
}

proc userlist_disconnected {server} {
    userlist_empty
}
