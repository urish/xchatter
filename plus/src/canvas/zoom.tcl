# $Id: zoom.tcl,v 1.1 2002-04-01 10:29:59 amirs Exp $

namespace eval zoomtool {
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
