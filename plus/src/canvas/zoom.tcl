# $Id: zoom.tcl,v 1.2 2002-04-01 10:39:20 amirs Exp $

namespace eval zoomtool {
    namespace import    [namespace parent]::register_tool

#    register_tool zoomin 	zoomtool {text 6 2 -anchor nw -font {Helvetica 24} -justify left -text "I"}
#    register_tool zoomout 	zoomtool {text 6 2 -anchor nw -font {Helvetica 24} -justify left -text "O"}


    proc press {x y shift} {
	switch [set [namespace parent]::tools(tool)] {
	    zoomin {
		.drawing_canvas.canvas scale all 0 0 2 2
	    }
	    zoomout {
		.drawing_canvas.canvas scale all 0 0 0.5 0.5
		.drawing_canvas.canvas xview moveto 0
		.drawing_canvas.canvas yview moveto 0
	    }
	}
    }
}
