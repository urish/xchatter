# $Id: rect.tcl,v 1.7 2002-04-01 10:52:49 amirs Exp $

namespace eval recttool {
    namespace import	[namespace parent]::align_to_grid_x	\
			[namespace parent]::align_to_grid_y	\
			[namespace parent]::align_line		\
			[namespace parent]::putcmd		\
			[namespace parent]::register_tool

    register_tool line	recttool {line 3 25 25 3 -fill black} 
    register_tool rectangle recttool {rectangle 25 25 4 4 -outline black}
    register_tool frectangle recttool {rectangle 25 25 4 4 -outline black -fill white}
    register_tool oval	recttool {oval 25 25 4 4 -outline black}
    register_tool foval	recttool {oval 25 25 4 4 -outline black -fill white}
    
    proc press {x y shift} {
	variable coords
	if {$shift & 0x4} {
	    set coords(x) [align_to_grid_x $x]
	    set coords(y) [align_to_grid_y $y]
	} else {
	    set coords(x) $x
	    set coords(y) $y
	}
    }
    
    proc gettype {} {
    	switch [set [namespace parent]::tools(tool)] {
	    line 	{ return "line" }
	    rectangle 	{ return "rectangle" }
	    frectangle	{ return "rectangle" }
	    oval 	{ return "oval" }
	    foval 	{ return "oval"	}
	}
    }
    
    proc getdef {} {
	variable coords
	set lnc [list [set [namespace parent]::colors(line)]]
	set flc [list [set [namespace parent]::colors(fill)]]
	set lnwidth [set [namespace parent]::linewidth]
	switch [set [namespace parent]::tools(tool)] {
	    line { 
		return "-fill $lnc -width $lnwidth"
	    }
	    rectangle {
		return "-outline $lnc -width $lnwidth"
	    }
	    frectangle {
		return "-fill $flc -outline $lnc -width $lnwidth"
	    }
	    oval {
		return "-outline $lnc -width $lnwidth"
	    }
	    foval {
		return "-fill $flc -outline $lnc -width $lnwidth"
	    }
	}
    }
    
    proc motion {x y shift} {
	variable coords
	variable tempitem
	if ![info exists coords] {
	    return
	}
	if {$shift & 0x1} {
	    set xy [align_line $coords(x) $coords(y) $x $y]
	    set x [lindex $xy 0]
	    set y [lindex $xy 1]
	}
	if {$shift & 0x4} {
	    set x [align_to_grid_x $x]
	    set y [align_to_grid_y $y]
	}
	if [info exists tempitem] {
	    .drawing_canvas.canvas coords $tempitem $coords(x) $coords(y) $x $y
	} else {
	    set tempitem [eval .drawing_canvas.canvas create [gettype] $coords(x) $coords(y) $x $y [getdef]]
	}
    }
    
    proc release {x y shift} {
	variable coords
	variable tempitem
	if ![info exists coords] {
	    return
	}
	if [info exists tempitem] {
	    unset tempitem
	}
	putcmd [gettype] "$coords(x) $coords(y) $x $y" "[getdef]"
	unset coords
    }
}
