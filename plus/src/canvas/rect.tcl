# $Id: rect.tcl,v 1.5 2002-03-31 19:15:39 amirs Exp $

namespace eval recttool {
    namespace import	[namespace parent]::align_to_grid_x	\
			[namespace parent]::align_to_grid_y	\
			[namespace parent]::align_line		\
			[namespace parent]::putcmd		

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
    
    proc getdef {x y} {
	variable coords
	set dcoords [list $coords(x) $coords(y) $x $y]
	set lnc [list [set [namespace parent]::colors(line)]]
	set flc [list [set [namespace parent]::colors(fill)]]
	set lnwidth [set [namespace parent]::linewidth]
	switch [set [namespace parent]::tools(tool)] {
	    line { 
		return "line $dcoords -fill $lnc -width $lnwidth"
	    }
	    rectangle {
		return "rectangle $dcoords -outline $lnc -width $lnwidth"
	    }
	    frectangle {
		return "rectangle $dcoords -fill $flc -outline $lnc -width $lnwidth"
	    }
	    oval {
		return "oval $dcoords -outline $lnc -width $lnwidth"
	    }
	    foval {
		return "oval $dcoords -fill $flc -outline $lnc -width $lnwidth"
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
	    set tempitem [eval .drawing_canvas.canvas create [getdef $x $y]]
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
	putcmd "[getdef $x $y]" 0
	unset coords
    }
}
