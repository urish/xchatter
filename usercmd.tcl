# XChatter user interface commands
# $Id: usercmd.tcl,v 1.21 2002-04-02 15:23:41 amirs Exp $

proc usercmd_init {} {
    # init timers
    global timers
    set timers(auto_counter) 0

    # register events
    onevent usercmd {
	;* 	{}
	M  	user_msg
	MSG	user_msg
	ACTION	user_act
	ME	user_act
	SLAP	user_slap
	BEEP	user_beep
	BELL	user_bell
	QUOTE	user_raw
	RAW	user_raw
	CLEAR	user_clear
	TCL	user_tcl
	PLUGIN	user_plus
	CONN	user_server
	CONNECT	user_server
	S	user_server
	SERVER	user_server
	DISC	user_disconnect
	DISCONNECT user_disconnect
	N	user_nick
	NICK	user_nick
	P	user_ping
	PING	user_ping
	ADMIN	user_admin
	DIE	user_die
	LOG	user_log
	KILL	user_kill
	BACK	user_back
	AWAY	user_away
	WHOIS	user_info
	INFO	user_info
	SINFO	user_sinfo
	SKIN	user_skin
	V	user_version
	VER	user_version
	VERSION	user_version
	TIME	user_time
	LIST	user_list
	QUIT	user_quit
	HELP	user_help
	EXEC	user_exec
	ECHO	user_echo
	PLUS	user_plus
	LOAD	user_load
	UNLOAD	user_unload
	ALIAS	user_alias
	TIMER   user_timer
	TIMERS	user_timers
	TIMESTAMP user_timestamp
    }
    
    # add a slap command
    userlist_menu_add "Slap" {user_slap ""}
}

proc process_command {text} {
    foreach i [split $text \n] {
        if {[string index $i 0] == "/"} {
	    if {[string index $i 1] == "/"} {
		set i [string range $i 1 end]
	    } else {
		user_cmd [split [string range $i 1 end] " "]
	        continue
	    }
	}
	if {$i != ""} {
	    user_glob $i
	}
    }
}

proc process_alias {name aargs} {
    global aliases
    foreach i $aliases {
	set aliasname [lindex $i 0]
	if {[string toupper $aliasname] == [string toupper $name]} {
	    set alias [lindex $i 1]
	}
    }
    if ![info exists alias] {
	return 0
    }
    set output ""
    while {[set j [string first {$} $alias]] != -1} {
	append output [string range $alias 0 [expr $j - 1]]
	set buf2 [string index $alias [expr $j + 2]]
	set buf3 [string index $alias [expr $j + 3]]
	switch -glob -- [string index $alias [expr $j + 1]] {
	    - {
		set to [string index $alias [expr $j + 2]]
		if [string match {[1234567890]} $to] {
		    append output [join [lrange $aargs 0 $to]]
	    	    set alias [string range $alias [expr $j + 3] end]
		} else {
		    append output [join $aargs]
	    	    set alias [string range $alias [expr $j + 2] end]
		}
	    }
	    {[0123456789]} {
		set from [string index $alias [expr $j + 1]]
		set dash [string index $alias [expr $j + 2]]
		if {$dash == "-"} {
		    set to [string index $alias [expr $j + 3]]
		    if {[string match {[0123456789]} $to]} {
		        append output [join [lrange $aargs $from $to]]
	    	        set alias [string range $alias [expr $j + 4] end]
		    } else {
		        append output [join [lrange $aargs $from end]]
	    	        set alias [string range $alias [expr $j + 3] end]
		    }
		} else {
		    append output [lindex $aargs $from]
	    	    set alias [string range $alias [expr $j + 2] end]
		}
	    }
	    {$} {
		append output {$}
		set alias [string range $alias [expr $j + 2] end]
	    }
	    default {
		append output [string range $alias $j [expr $j + 1]]
		set alias [string range $alias [expr $j + 2] end]
	    }
	}
    }
    append output $alias
    process_command $output
    return 1
}

proc user_cmd {text} {
    global aliases aliaslevel errorInfo
    set cmd [lindex $text 0]
    set args [lrange $text 1 end]
    if {[incr aliaslevel] > 100} {
	putcmsg alias_loop d $aliaslevel
	set aliaslevel 0
	return
    }
    if [process_alias $cmd $args] {
	return
    }
    if ![process_event usercmd [string toupper $cmd] $args] {
	putcmsg invalid_cmd t $cmd
    }
    set aliaslevel 0
}

proc user_glob {text} {
    global nick
    if [process_event userglob $text $text] {
	return
    }
    putsock "GLOBAL $text"
    if [info exists nick] {
	putcmsg sent_glob_msg n $nick t $text
    } else {
	putcmsg sent_glob_msg n unregistered-user t $text
    }
    return 1
}

proc user_msg {uargs} {
    set target	[lindex $uargs 0]
    set text	[join [lrange $uargs 1 end]]
    putsock "MSG $target $text"
    putcmsg sent_priv_msg n $target t $text
    return 1
}

proc user_act {uargs} {
    global nick
    putsock "GCMD ACTION [join $uargs]"
    putcmsg sent_action n $nick t [join $uargs]
    return 1
}

proc user_slap {uargs {menu_nick ""}} {
    if {$menu_nick != ""} {
	set cnick $menu_nick
    } else {
	set cnick [lindex $uargs 0]
    }
    user_act "slaps $cnick with a large unix manual"
    return 1
}

proc user_beep {uargs} {
    set target	[lindex $uargs 0]
    set text	[join [lrange $uargs 1 end]]
    putsock "CMD $target BEEP $text"
    putcmsg sent_beep n $target t $text
    return 1
}

proc user_bell {uargs} {
    bell
    return 1
}

proc user_raw {uargs} {
    putsock [join $uargs]
    putcmsg raw t [join $uargs]
    return 1
}

proc user_kill {uargs} {
    set user	[lindex $uargs 0]
    set reason	[join [lrange $uargs 1 end]]
    putsock "KILL $user $reason"
    return 1
}

proc user_die {uargs} {
    putsock "DIE [join $uargs]"
    putcmsg server_die t [join $uargs]"
    return 1
}

proc user_log {uargs} {
    global logfile
    set fname [lindex $uargs 0]
    if {$fname == ""} {
	set logfile ""
	putcmsg logging_stopped
	return 1
    }
    set error [catch {
        set fd [open $fname a+]
        puts $fd "\n---> Logging started at [clock format [clock seconds] -format "%d/%m/%Y"]\n"
	close $fd
	putcmsg logging_started n $fname
        set logfile $fname
    } errtext]
    if $error {
	putcmsg logging_error s $errtext
    }
    return 1
}

proc user_disconnect {uargs} {
    if [disconnect] {
	putcmsg disconnected
    }
    return 1
}

proc user_server {uargs} {
    global user_last_nick
    set server [lindex $uargs 0]
    set port [lindex $uargs 1]
    if {$port == ""} {set port 6970}
    if [is_connected] {
	putcmsg terminate_conn
	disconnect
    }
    if {[set err [connect $server $port]] != ""} {
	putcmsg conn_error s $server p $port t $err
    } else {
	if [info exists user_last_nick] {
	    putsock "NICK $user_last_nick"
	    putcmsg connected_nick s $server p $port n $user_last_nick
	} else {
	    putcmsg connected s $server p $port
	}
    }
    return 1
}

proc user_nick {uargs} {
    global user_last_nick
    if {[string tolower [lindex $uargs 0]] == "--nosave" ||
	    [string tolower [lindex $uargs 0]] == "-n"} {
	set nick [lindex $uargs 1]
    } else {
	set nick [lindex $uargs 0]
	set user_last_nick $nick
    }
    if ![putsock "NICK $nick" 1] {
	putcmsg nick_not_connected n $nick
    }
    return 1
}

proc user_info {uargs} {
    putsock "INFO [lindex $uargs 0]"
    return 1
}

proc user_sinfo {uargs} {
    putsock "SINFO"
    return 1
}

proc user_time {uargs} {
    if {$uargs == ""} {
	putcmsg time_is t [clock format [clock seconds]]
	return
    }
    putsock "CMD [lindex $uargs 0] TIME"
    return 1
}

proc user_version {uargs} {
    set user [lindex $uargs 0]
    if {$user == ""} {
	putsock "VERSION"
	putcmsg requested_server_version
	return 1
    }
    putsock "CMD $user VERSION"
    putcmsg requested_version n $user
    return 1
}

proc user_ping {uargs} {
    set user [lindex $uargs 0]
    if {$user == ""} {
	putsock "PING @ [clock seconds] 0"
	putcmsg server_ping
	return 1
    }
    putsock "PING $user [clock seconds] 0"
    putcmsg user_ping n $user
    return 1
}

proc user_admin {uargs} {
    putsock "ADMIN [lindex $uargs 0]"
    return 1
}

proc user_away_timer {} {
    global away
    user_act "is still away ($away(reason)) since [duration [expr [clock seconds] - $away(since)]]"
    return 1
}

proc user_away {uargs} {
    global away
    set uargs [string trim [join $uargs]]
    if {$uargs == ""} {
	if ![info exists away(reason)] {
	    putcmsg back_not_away
	    return 1
	}
	putsock "GCMD ACTION is back from death: was away for [duration [expr [clock seconds] - $away(since)]]."
	putcmsg away_back t [duration [expr [clock seconds] - $away(since)]]
	rm_timer away
	unset away
	return 1
    }
    if [info exists away(reason)] {
	set away(reason) $uargs
	putsock "GCMD ACTION has changed his away reason ($uargs)"
	putcmsg away_reason_changed t $uargs
	return 1
    }
    set away(reason) $uargs
    set away(since) [clock seconds]
    timer away tcl [expr 15 * 60000] 0 user_away_timer
    user_act "is away ($uargs)"
    putcmsg away_set t $uargs
    return 1
}

proc user_back {args} {
    return [user_away ""]
}

proc user_list {uargs} {
    putsock "LIST"
    return 1
}

proc user_skin {uargs} {
    load_skin [lindex $uargs 0]
    return 1
}

proc user_quit {uargs} {
    putsock "QUIT [join $uargs]"
    exit
}

proc user_tcl {uargs} {
    if {[lindex $uargs 0] == "-q"} {
	set quiet 1
	set uargs [lrange $uargs 1 end]
    } 
    if {[lindex $uargs 0] == "-o"} {
	set server_output 1
	set cmd [join [lrange $uargs 1 end]]
    } else {
	set cmd [join $uargs]
    }
    if [catch $cmd err] {
	putcmsg tcl_error t $err
    } else {
	if [info exists server_output] {
	    catch {user_glob $err}
	} else {
	    if ![info exists quiet] {
		putcmsg tcl_result t $err
	    }
	}
    }
    return 1
}

proc user_exec_input {idx} {
    global bgexec
    if [eof $idx] {
	fileevent $idx readable ""
	catch {close $idx}
	unset bgexec($idx)
	return
    }
    set line [gets $idx]
    if {$line == "" && [eof $idx]} {
	return
    }
    if {$line == ""} {
	set line " "
    }
    if {$bgexec($idx)} {
	catch {user_glob $line}
    } else {
	putcmsg exec_result t $line
    }
    return
}

proc user_exec {uargs} {
    global bgexec
    if {[string tolower [lindex $uargs 0]] == "-o"} {
	set server_output 1
	set cmd [join [lrange $uargs 1 end]]
    } else {
	set server_output 0
	set cmd [join $uargs]
    }
    if [catch {open |$cmd r} err] {
	putcmsg exec_error t $err
	return 1
    }
    fconfigure $err -blocking 0
    set bgexec($err) $server_output
    fileevent $err readable [list user_exec_input $err]
    return 1
}

proc user_alias {uargs} {
    global aliases
    set uargs [split [string trim [join $uargs]]]
    if {$uargs == ""} {
	set alias_cnt 0
	foreach i $aliases {
	    putcmsg alias_list_entry a [lindex $i 0] t [join [split [lindex $i 1] \n] "\002;\002 "]
	    incr alias_cnt
	}
	putcmsg alias_list_end d $alias_cnt
	return 1
    }
    set alias [lindex $uargs 0]
    set overwrite 1
    if {[string index $alias 0] == "+"} {
	set alias [string range $alias 1 end]
	set overwrite 0
    }
    set counter -1
    foreach i $aliases {
	incr counter
	if {[string toupper $alias] == [string toupper [lindex $i 0]]} {
	    set aliasloc $counter
	    set old_aliascmd [lindex $i 1]
	    break
	}
    }
    set aliascmd [string trim [join [lrange $uargs 1 end]]]
    if {$aliascmd == ""} {
	if [info exists aliasloc] {
	    set aliases [concat [lrange $aliases 0 [expr $aliasloc - 1]] [lrange $aliases [expr $aliasloc + 1] end]]
	    putcmsg alias_removed a $alias
	    return 1
	} else {
	    putcmsg alias_not_exists a $alias
	    return 1
	}
    } else {
	if [info exists aliasloc] {
	    if $overwrite {
		set aliases [lreplace $aliases $aliasloc $aliasloc [list $alias $aliascmd]]
	    } else {
		set aliases [lreplace $aliases $aliasloc $aliasloc [list $alias "$old_aliascmd\n$aliascmd"]]
	    }
	    putcmsg alias_modified a $alias t $aliascmd
	    return 1
	} else {
	    lappend aliases [list $alias $aliascmd]
	    putcmsg alias_added a $alias t $aliascmd
	    return 1
	}
    }
    return 1
}

proc user_echo {uargs} {
    putchat [join $uargs]
    return 1
}

proc user_plus {uargs} {
    putcmsg no_plus
    return 1
}

proc user_load {uargs} {
    if ![llength [info commands load_extension]] {
	putcmsg no_plugins_loader
	return 1
    }
    foreach ext $uargs {
	load_extension $ext
    }
    return 1
}

proc user_unload {uargs} {
    if ![llength [info commands unload_extension]] {
	putcmsg no_plugins_loader
	return 1
    }
    foreach ext $uargs {
	unload_extension $ext
    }
    return 1
}

proc get_interval {interval} {
    set timeunit 1000
    set tudigits 0
    switch -glob -- $interval {
    *ms {
        set timeunit 1
	set tudigits 2
    }
    *m {
        set timeunit 60000
	set tudigits 1
    }
    *s {
        set timeunit 1000
	set tudigits 1
    }
    *h {
        set timeunit 3600000
	set tudigits 1
    }
    }
    set interval [string range $interval 0 [expr [string length $interval] - $tudigits - 1]]
    if [catch {expr int($interval*$timeunit)} interval] {
	return ""
    }
    if {$interval <= 0} {
	return ""
    }
    return $interval
}

proc get_interval_name {i} {
    if {$i % 1000} {
	return "${i}ms"
    }
    if {$i % 60000} {
	return "[expr $i / 1000]s"
    }
    if {$i % 3600000} {
	return "[expr $i / 60000]m"
    }
    return "[expr $i / 3600000]h"
}

proc user_timers {uargs} {
    putcmsg timer_list_start
    set timer_cnt 0
    foreach i [timers tcl *] {
	set int [timer_info $i interval]
	putcmsg timer_list_tclentry n $i t [timer_info $i command] i $int I [get_interval_name $int]
	incr timer_cnt
    }
    foreach i [timers script *] {
	set int [timer_info $i interval]
	putcmsg timer_list_entry n $i t [timer_info $i command] i $int I [get_interval_name $int]
	incr timer_cnt
    }
    putcmsg timer_list_end d $timer_cnt
    return 1
}

proc user_timer {uargs} {
    global timers
    set name [strtok uargs]
    switch -glob -- [string toupper $name] {
	-* {
	    if [string match "-?*" $name] {
		set name [string range $name 1 end]
	    } else {
	    	set name [strtok uargs]
	    }	
	    if {$name == ""} {
		putcmsg timer_error_noname
		return 1
	    }
	    if {[timer_info $name type] != "script" && [timer_info $name type] != ""} {
		putcmsg timer_error_internal
		return 1
	    }
	    if [rm_timer $name] {
		putcmsg timer_del_done n $name
	    } else {
		putcmsg timer_del_error n $name
	    }
	}
	* {
	    if [string match "+?*" $name] {
		set name [string range $name 1 end]
	    }
	    set interval [split [strtok uargs] :]
	    set count [lindex $interval 1]
	    set interval [lindex $interval 0]
	    set command [strrest uargs]
	    if {$name == ""} {
		putcmsg timer_error_noname
		return 1
	    }
	    if {[string tolower [string range $name 0 1]] == "t#"} {
		putcmsg timer_error_badname
		return 1
	    }
	    if {[string tolower $name] == "auto"} {
		set name "t#[incr timers(auto_counter)]"
	    }
	    if {$interval == ""} {
		putcmsg timer_error_nointerval
		return 1
	    }
	    set interval [get_interval $interval]
	    if {$interval == ""} {
		putcmsg timer_error_badinterval
		return 1
	    }
	    set type [timer_info $name type]
	    if {$command == "" && $type == ""} {
		putcmsg timer_error_nocmd
		return 1
	    }
	    if {$type == ""} { 
		set type script
	    }
	    if {$count == ""} {
		set count 0
	    }
	    if [catch {expr $count + 1}] {
		putcmsg timer_error_badcount
		return 1
	    }
	    if {$type != "script" && ($command != "" || $count != [timer_info $name count])} {
		putcmsg timer_error_internal
		return 1
	    }
	    timer $name $type $interval $count $command
	}
    }
    return 1
}

proc user_timestamp {uargs} {
    global timestamp
    if {[string index [string toupper [join $uargs]] 0] == "N" ||
	[string match "OFF*" [string toupper [join $uargs]]]} {
	set timestamp 0
    } else {
	set timestamp 1
    }
    return 1
}

proc user_help {uargs} {
    global helploaded
    if {!$helploaded} {
	putcmsg help_not_loaded
	return 1
    }
    show_help [join $uargs]
    return 1
}

proc user_clear {uargs} {
    clear_chat
    return 1
}
