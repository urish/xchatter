EXTENTION server VERSION 1.10 BUILD 1
# settings:
variable adminpass "LetMein"
variable port 6970

# Start of code.
variable version 1.10
variable protver 205
variable uptime [clock seconds]

set help {
    0	GLOBAL	{<msg>}		 {send <msg> to all clients}
    0	MSG	{<client> <msg>} {send <client> message <msg>}
    0	GCMD 	{<cmd>}		 {send command <cmd> to all clients}
    0	CMD	{<client> <cmd>} {send commnad <cmd> to <client>}
    0	PING	{[client] [msg]} {PING client WITH msg}
    0	PONG	{[client] [msg]} {reply to a ping command}
    0	LIST	{}		 {retrive a list of online users}
    0	NICK	{<newnick>}	 {change nick to <newnick>}
    0	QUIT	{[msg]}		 {leave the server}
    0	INFO	{<client>}	 {get information about a client}
    0	ADMIN	{<password>}	 {get administration priviliges}
    0	VERSION	{}		 {get server version}
    0	PROTVER {}		 {get protocol version}
    1	DIE	{[reason]}	 {terminate the server}
    1	KILL	{<client> <reason>} {disconnect a client}
    0	HELP	{}		 {get help}
}

proc remove_client {idx reason} {
    variable clients
    if ![info exists clients(i,$idx)] {
	return
    }
    set name [string tolower $clients(i,$idx)]
    fileevent $idx readable ""
    if {$name != ""} {
	unset clients(n,$name)
    }
    foreach i [array names clients ?,$idx] {
	unset clients($i)
    }
    close $idx
    if [llength $name] {
	tell_all_but_one "QUIT $name $reason" $idx
    }
}

proc putsock {idx msg} {
    if [catch {puts $idx $msg}] {
	remove_client $idx "Socket write error"
    }
}

proc tell_all_but_one {msg idx} {
    variable clients
    foreach i [array names clients i,*] {
	set iidx [string range $i 2 end]
	if {$iidx != $idx && $iidx != "" && $clients($i) != ""} {
	    putsock $iidx $msg
	}
    }
}

proc send_admins {msg} {
    variable clients
    foreach i [array names clients a,*] {
	if !$clients($i) {
	    continue
	}
	putsock [string range $i 2 end] $msg
    }
}

proc disconnect_all_clients {reason} {
    variable clients
    foreach i [array names clients i,*] {
	set idx [string range $i 2 end]
	putsock $idx "BYE $reason"
	fileevent $idx readable ""
	close $idx
    }
    catch {unset clients}
}

proc new_client {idx addr port} {
    variable clients
    fconfigure $idx -buffering none
    set clients(i,$idx) ""
    set clients(l,$idx) [clock seconds]
    set clients(a,$idx) 0
    set clients(A,$idx) $addr
    set clients(c,$idx) [clock seconds]
    fileevent $idx readable [list [namespace current]::incoming_text $idx]
}

proc check_register {idx} {
    variable clients
    if {$clients(i,$idx) == ""} {
	putsock $idx "ERROR 100 You are not registered."
	return -code return
    }
}

proc check_admin {idx} {
    variable clients
    if !$clients(a,$idx) {
	putsock $idx "ERROR 107 Permission denied."
	return -code return
    }
}

proc client_nick {idx arglist} {
    variable clients
    set newname [lindex $arglist 0]
    set name $clients(i,$idx)
    if {[string length $newname] < 2 || [string length $newname] > 16 ||
	[string index $newname 0] == "@"} {
	putsock $idx "ERROR 105 $newname Invalid nick."
	return 0
    }
    if [info exists clients(n,[string tolower $newname])] {
	putsock $idx "ERROR 106 $newname Nick is already in use."
	return 0
    }
    if {$name != ""} {
 	unset clients(n,$name)
    }
    set clients(i,$idx) $newname
    set clients(n,[string tolower $newname]) $idx
    if {$name == ""} {
  	tell_all_but_one "JOIN $newname" $idx
	putsock $idx "USER $newname"
    } else {
	tell_all_but_one "NICK $name $newname" ""
    }
}

proc client_quit {idx args} {
    putsock $idx "BYE"
    set args [string trim [join $args]]
    if {$args == ""} {
	remove_client $idx "Client exited."
    } else {
 	remove_client $idx $args
    }
}

proc list_clients {idx} {
    variable clients
    foreach i [array names clients i,*] {
	set iidx [string range $i 2 end]
	if {$clients(i,$iidx) == ""} {
	    continue
	}
	# FD 0 is require for compatibility with minichat. To be removed in
	# future versions.
	putsock $idx "LIST $clients(i,$iidx) FD 0 IP $clients(A,$iidx)"
    }
    putsock $idx "LIST END"
}

proc get_client_by_name {idx name} {
    variable clients
    set lname [string tolower $name]
    if ![info exists clients(n,$lname)] {
	putsock $idx "ERROR 104 $name no such user."
	return -code return ""
    }
    return $clients(n,$lname)
}

proc client_to_client {type idx arglist} {
    variable clients
    check_register $idx
    set name $clients(i,$idx)
    set ltarget [string tolower [lindex $arglist 0]]
    if {$type == "PING" && ($ltarget == "@" || $ltarget == "@server")} {
	putsock $idx "PONG @SERVER [join [lrange $arglist 1 end]]"
	return
    }
    set oidx [get_client_by_name $idx [lindex $arglist 0]]
    putsock $oidx "$type $name [join [lrange $arglist 1 end]]"
}

proc client_gmsg {type idx msg} {
    variable clients
    check_register $idx
    tell_all_but_one "$type $clients(i,$idx) $msg" $idx
}

proc client_help {idx} {
    variable help
    variable version
    putsock $idx "HELP Communications Center v$version by Uri Shaked <uri@keves.org>"
    foreach {flag cmd args desc} $help {
	if {$flag && !$clients(a,$idx)} {
	    continue
        }
	putsock $idx [format "HELP %8s%16s%s" $cmd $args $desc]
    }
}

proc client_version {idx} {
    variable version
    upvar #0 version xcver
    putsock $idx "VERSION Communications Center v$version by Uri Shaked <uri@keves.org> - Loaded as XChatter v$xcver extension."
}

proc client_protver {idx} {
    variable protver
    putsock $idx "PROTVER $protver"
}

proc client_info {idx arglist} {
    variable clients
    check_register $idx
    if {$arglist == ""} {
	client_sinfo $idx
	return
    }
    set oidx [get_client_by_name $idx [lindex $arglist 0]]
    putsock $idx "INFO $clients(i,$oidx) IP $clients(A,$oidx) IDLE [expr [clock seconds] - $clients(l,$oidx)] CONNECTED $clients(c,$oidx)"
}

proc client_sinfo {idx} {
    variable clients
    variable uptime
    check_register $idx
    set clnt 0
    set unknown 0
    foreach i [array names clients i,*] {
	if {$clients($i) == ""} {
	    incr unknown
	} else {
	    incr clnt
	}
    }
    putsock $idx "SINFO CLIENTS $clnt UNKNOWN $unknown UPTIME [expr [clock seconds] - $uptime]"
}

proc client_admin {idx arglist} {
    variable adminpass
    variable clients
    check_register $idx
    if {$adminpass == "" || $adminpass != [lindex $arglist 0]} {
	putsock $idx "ERROR 107 Permission denied."
	send_admins "MSG @SERVER Client $clients(i,$idx) failed to identify as admin (password was: [lindex $arglist 0])"
	return
    }
    if {$adminpass == "off"} {
	check_admin $idx
	set clients(a,$idx) 0
	putsock $idx "ADMIN 201 You are not a system administrator anymore."
    }
    set clients(a,$idx) 1
    putsock $idx "ADMIN 200 You are now a system administrator."
}

proc client_die {idx arglist} {
    variable clients
    variable server_sock
    check_admin $idx
    putcmsg xcplus_server_die n $clients(i,$idx) s [join $arglist]
    send_admins "MSG @SERVER Server terminated by $clients(i,$idx) ([join $arglist])"
    disconnect_all_clients "Server terminated: [join $arglist]"
    close $server_sock
    unset server_sock
}

proc client_kill {idx arglist} {
    variable clients
    variable server_sock
    check_admin $idx
# FIX ME
    send_admins "MSG @SERVER Server terminated by $clients(i,$idx) ([join $arglist])"
    disconnect_all_clients "Server terminated: [join $arglist]"
    close $server_sock
}

proc incoming_text {idx} {
    variable clients
    if [catch {split [gets $idx] " "} buf] {
	remove_client $idx "Read error: $buf"
	return
    }
    if [eof $idx] {
	remove_client $idx "EOF from client"
	return
    }
    set args [lrange $buf 1 end]
    switch -exact -- [string toupper [lindex $buf 0]] {
	PING - PONG - MSG - CMD {
	    client_to_client [lindex $buf 0] $idx $args
	}
	QUIT { client_quit $idx}
	LIST { list_clients $idx}
	GLOB - GLOBAL { client_gmsg GLOBAL $idx [join $args]} 
	GCMD { client_gmsg GCMD $idx [join $args]} 
	NICK { client_nick $idx $args }
	INFO { client_info $idx $args }
	SINFO { client_sinfo $idx }
	HELP - ? { client_help $idx }
	VER - VERSION { client_version $idx }
	PROTVER { client_protver $idx }
	ADMIN { client_admin $idx $args }
	default {
	    putsock $idx "ERROR 103 [lindex $buf 0] invalid command."
	}
    }
    set clients(l,$idx) [clock seconds]
}

<@INCLUDE interface.tcl>
