proc iface_show {} {
    variable server_sock
    set base .miniserver
    set root $base
    
    toplevel $base
    wm title $base "XChatter MiniServer control panel"
    wm resizable $base 0 0

    frame $base.frame#3
    frame $base.frame#1
    label $base.label#2		-text Port:
    entry $base.entry_port	-textvariable [namespace current]::port
    label $base.label#4		-text {Admin pass:}
    entry $base.entry_adminpass	-textvariable [namespace current]::adminpass -show *
    label $base.label#5		-text Users:
    label $base.label_usercnt	-text 0
    if [info exists server_sock] {
	set text "Stop server"
        trace variable server_sock u [namespace current]::server_stopped
        trace variable clients w [namespace current]::update_client_cnt
    } else {
	set text "Start server"
    }
    button $base.startstop	-text $text -command [namespace current]::iface_start_stop_server
    button $base.close		-text Close -command [namespace current]::iface_hide
    button $base.help		-text Help

    # Geometry management
    grid $base.frame#3 -in $root	-row 1 -column 1 
    grid $base.frame#1 -in $root	-row 2 -column 1 
    grid $base.label#2 -in $base.frame#3	-row 1 -column 1  \
	    -sticky w
    grid $base.entry_port -in $base.frame#3	-row 1 -column 2  \
	    -sticky ew
    grid $base.label#4 -in $base.frame#3	-row 2 -column 1  \
	    -sticky w
    grid $base.entry_adminpass -in $base.frame#3 -row 2 -column 2  \
	    -sticky ew
    grid $base.label#5 -in $base.frame#3	-row 3 -column 1  \
	    -sticky w
    grid $base.label_usercnt -in $base.frame#3	-row 3 -column 2  \
	    -sticky w
    grid $base.startstop -in $base.frame#1	-row 1 -column 1 
    grid $base.close -in $base.frame#1	-row 1 -column 2 
    grid $base.help -in $base.frame#1	-row 1 -column 3 

    # Resize behavior management
    grid rowconfigure $base.frame#3 1 -weight 0 -minsize 2
    grid rowconfigure $base.frame#3 2 -weight 0 -minsize 13
    grid rowconfigure $base.frame#3 3 -weight 0 -minsize 5
    grid columnconfigure $base.frame#3 1 -weight 0 -minsize 30
    grid columnconfigure $base.frame#3 2 -weight 0 -minsize 189
    grid rowconfigure $root 1 -weight 0 -minsize 31
    grid rowconfigure $root 2 -weight 0 -minsize 30
    grid columnconfigure $root 1 -weight 0 -minsize 30
    grid rowconfigure $base.frame#1 1 -weight 0 -minsize 30
    grid columnconfigure $base.frame#1 1 -weight 0 -minsize 30
    grid columnconfigure $base.frame#1 2 -weight 0 -minsize 30
    grid columnconfigure $base.frame#1 3 -weight 0 -minsize 30
}

proc iface_hide {} {
    catch {
	destroy .miniserver
    }
}

proc start_server {} {
    variable port
    variable server_sock
    variable clients
    if [info exists server_sock] {
	putcmsg xcplus_server_already_start
	return
    }
    if [catch {socket -server [namespace current]::new_client $port} error] {
        putcmsg xcplus_server_error p $port s $error
	return 0
    }
    putcmsg xcplus_server_start p $port
    set server_sock $error
    catch {
	.miniserver.startstop configure -text "Stop server"
        trace variable server_sock u [namespace current]::server_stopped
        trace variable clients w [namespace current]::update_client_cnt
    }
}

proc server_stopped {args} {
    variable server_sock
    .miniserver.startstop configure -text "Start server"
    .miniserver.label_usercnt configure -text "0"
    trace vdelete server_sock u [namespace current]::server_stopped
    trace vdelete clients w [namespace current]::update_client_cnt
}

proc update_client_cnt {args} {
    variable clients
    .miniserver.label_usercnt configure -text [llength [array names clients i,*]]
}

proc stop_server {} {
    variable server_sock
    if ![info exists server_sock] {
	putcmsg xcplus_server_already_stop
	return
    }
    putcmsg xcplus_server_die n "local agent" s "Stop button clicked"
    send_admins "MSG @SERVER Server terminated by local agent."
    disconnect_all_clients "Server terminated: local agent termination."
    close $server_sock
    unset server_sock
}

proc iface_start_stop_server {} {
    variable server_sock
    if [info exists server_sock] {
	stop_server
    } else {
	start_server
    }
}

proc ucmd_mserver {uargs} {
    variable port
    variable adminpass
    set uargs [split $uargs]
    switch -glob -- [string tolower [lindex $uargs 0]] {
	{[123456789]*} {
	    set port [lindex $uargs 0]
	    if {[lindex $uargs 1] != ""} {
		set adminpass [lindex $uargs 1]
	    }
	    start_server
	}
	stop {
	    stop_server
	}
	start {
	    if {[lindex $uargs 1] != ""} {
		set port [lindex $uargs 1]
	    }
	    if {[lindex $uargs 2] != ""} {
		set adminpass [lindex $uargs 2]
	    }
	    start_server
	}
	help {
	}
	hide {
	    iface_hide
	}
	default {
	    catch {
		iface_show
	    }
	}	
    }
    return 1
}

proc init {} {
    variable server_sock
    register_msgs {
	xcplus_server_start "*** XCServer: Starting AiCP server, port %p."
	xcplus_server_already_start
			    "*** Error: Server is already started."
	xcplus_server_already_stop
			    "*** Error: Server is already stopped."
	xcplus_server_error "*** Error: Unable to listen on port %p: %s."
        xcplus_server_die   "*** XCServer: Server terminated by %n (%s)."
	xcplus_server_loaded "*** XChatter server extension loaded. Type /miniserver to get into control window."
    }
    putcmsg xcplus_server_loaded
    onevent usercmd MSERVER [namespace current]::ucmd_mserver \
		    MINISERVER [namespace current]::ucmd_mserver
}

proc unload {} {
    variable server_sock
    unevent usercmd [namespace current]::ucmd_mserver \
		    [namespace current]::ucmd_mserver
    iface_hide
    if [info exists server_sock] {
	stop_server
    }
}
