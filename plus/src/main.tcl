# Initialize plugin
# $Id: main.tcl,v 1.1 2001-07-25 15:32:14 uri Exp $

namespace eval xcplus {
    variable version __XCPLUS_VERSION__
    variable numver __XCPLUS_NUMVER__
    variable loaded_exts ""
    variable extentions
    array set extentions __EXTENTIONS__
    
    proc init {} {
        onevent usercmd {
	    LOAD	xcplus::ucmd_load
	    UNLOAD	xcplus::ucmd_unload
	}
	register_msgs {
	    unknown_subcmd	"*** Unknown sub-command '%s'."
	    xcplus_loaded	"*** XChatter plus %v plugin loaded."
	    xcplus_load_usage	"*** Usage: /LOAD <extention name> ..."
	    xcplus_extlist	"*** Available extentions: %t."
	    xcplus_allloaded	"*** All extentions loaded."
	    xcplus_extloaded	"*** Extention %t v%v loaded."
	    xcplus_extunknown	"*** Error: unknown extention %t."
	    xcplus_unload_usage	"*** Usage: /UNLOAD <extention name> ..."
	    xcplus_loaded_extlist "*** Extentions loaded: %t."
	    xcplus_extunloaded	"*** Extention %t successfully unloaded."
	    xcplus_allunloaded	"*** All extentions succesfully unloaded."
	    xcplus_unloaded	"*** XChatter plus unloaded."
	    xcplus_extnotloaded "*** Error: can't unload extention %t: no such extention loaded."
	}
    }
    
    proc destroy {} {
	variable loaded_exts
	foreach i $loaded_exts {
	    catch {${i}::destroy}
	}
	unevent usercmd {
	    xcplus::ucmd_load
	    xcplus::ucmd_unload
	}
	namespace delete [namespace current]
    }
    
    proc ucmd_load {uargs} {
	variable extentions
	variable loaded_exts
	if {[string trim [join $uargs]] == ""} {
	    set extlist ""
	    foreach i [array names extentions *,version] {
		lappend extlist [lindex [split $i ,] 0]
	    }
	    putcmsg xcplus_load_usage
	    putcmsg xcplus_extlist t [join [lsort -dictionary $extlist] ", "]
	    return 1
	}
	foreach extname $uargs {
	    if {$extname == ""} {
		continue
	    }
	    if {[lsearch -exact $loaded_exts $extname] != -1} {
		putcmsg xcplus_ext_already t $extname
		continue
	    }
	    if {$extname == "all" || $extname == "*"} {
		foreach extent [array names extentions *,script] {
		    set ext [lindex [split $extent ,] 0]
		    if {[lsearch -exact $loaded_exts $extname] >= 0} {
			continue
		    }
		    eval $extentions($extent)
		    ${ext}::init
		    lappend loaded_exts $ext
		}
		putcmsg xcplus_allloaded
		continue
	    }
	    if [info exists extentions($extname,script)] {
		eval $extentions($extname,script)
		${extname}::init
		putcmsg xcplus_extloaded t $extname v [lindex $extentions($extname,version) 0]
		lappend loaded_exts $extname
	    } else {
		putcmsg xcplus_extunknown t $extname
	    }
	}
	return 1
    }
    
    proc ucmd_unload {uargs} {
	variable loaded_exts
	if {[string trim [join $uargs]] == ""} {
	    set extlist ""
	    putcmsg xcplus_unload_usage
	    putcmsg xcplus_loaded_extlist t [join [lsort -dictionary $loaded_exts] ", "]
	    return 1
	}
	foreach extname $uargs {
	    if {$extname == ""} {
		continue
	    }
	    if {$extname == "xcplus" || $extname == "." || $extname == "self"} {
		destroy
		putcmsg xcplus_unloaded
		return 1
	    }
	    if {$extname == "all" || $extname == "*"} {
		foreach ext $loaded_exts {
		    ${ext}::destroy
		}
		set loaded_exts ""
		putcmsg xcplus_allunloaded
		continue
	    }
	    if {[set ptr [lsearch -exact $loaded_exts $extname]] != -1} {
		${extname}::destroy
		set loaded_exts [lreplace $loaded_exts $ptr $ptr]
		putcmsg xcplus_extunloaded t $extname
	    } else {
		putcmsg xcplus_extnotloaded t $extname
	    }
	}
	return 1
    }
    
    proc is_extention_loaded {name} {
	variable loaded_exts
	return [expr [lsearch -exact $loaded_exts $name] >= 0]
    }
    
    proc extentions {} {
	variable loaded_exts
	return $loaded_exts
    }

    putcmsg xcplus_loaded v $version
}
