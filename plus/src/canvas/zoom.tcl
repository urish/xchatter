# $Id: zoom.tcl,v 1.3 2002-04-01 11:04:59 amirs Exp $

namespace eval zoomtool {
    namespace import    [namespace parent]::register_tool	\
			[namespace parent]::addslashes
    
    rename [namespace parent]::putcmd [namespace current]::putcmd

    register_tool zoomin 	zoomtool {text 6 2 -anchor nw -font {Helvetica 24} -justify left -text "I"}
    register_tool zoomout 	zoomtool {text 6 2 -anchor nw -font {Helvetica 24} -justify left -text "O"}

    variable zoom "1.0"

    proc press {x y shift} {
	variable zoom
	switch [set [namespace parent]::tools(tool)] {
	    zoomin {
		.drawing_canvas.canvas scale all 0 0 2 2
		set zoom [expr $zoom * 0.5]
	    }
	    zoomout {
		.drawing_canvas.canvas scale all 0 0 0.5 0.5
		.drawing_canvas.canvas xview moveto 0
		.drawing_canvas.canvas yview moveto 0
		set zoom [expr $zoom * 2]
	    }
	}
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
