# $Id: zoom.tcl,v 1.5 2002-04-01 12:11:36 amirs Exp $

namespace eval zoomtool {
    namespace import    [namespace parent]::register_tool	\
			[namespace parent]::addslashes
    
    rename [namespace parent]::putcmd [namespace current]::putcmd

    register_tool zoomin 	zoomtool {text 6 2 -anchor nw -font {Helvetica 24} -justify left -text "I"}
    register_tool zoomout 	zoomtool {text 6 2 -anchor nw -font {Helvetica 24} -justify left -text "O"}
    register_tool zoomnormal 	zoomtool {text 6 2 -anchor nw -font {Helvetica 24} -justify left -text "N"}

    variable zoom "1.0"

    proc press {x y shift} {
	variable zoom
	switch [set [namespace parent]::tools(tool)] {
	    zoomin {
		.drawing_canvas.canvas scale all 0 0 2 2
		set zoom [expr $zoom * 0.5]
		set x [expr $x * 2]
		set y [expr $y * 2]
	    }
	    zoomout {
		.drawing_canvas.canvas scale all 0 0 0.5 0.5
		set zoom [expr $zoom * 2.0]
		set x [expr $x * 0.5]
		set y [expr $y * 0.5]
	    }
	    zoomnormal {
		if {$zoom > 1.0} {
		    set q 0.5
		    set w 2.0
		} elseif {$zoom < 1.0} {
		    set q 2.0
		    set w 0.5
		} else {
		    return
		}
		
		for {set i $zoom} {$i != 1.0} {set i [expr $i * $q]} {
		    .drawing_canvas.canvas scale all 0 0 $w $w
		    set x [expr $x * $w]
		    set y [expr $y * $w]
		}	
		set zoom $i
	    }
	}
#	.drawing_canvas.canvas xview scroll $x units
#	.drawing_canvas.canvas yview scroll $y units
    }

    proc putcmd {type coordinates options} {
	variable zoom
	set ncoords ""
	foreach i $coordinates {
	    lappend ncoords [expr $i * $zoom]
	}
	putsock "GCMD DRAW $type $ncoords [addslashes $options]" 1
    }
}
