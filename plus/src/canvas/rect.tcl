namespace eval recttool {
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
    
    proc getdef {} {
	variable tool
	variable start_coords
	variable linewidth
	variable colors
	variable polycoords
	set coords [canvas_getcoords $x $y]
	set lnc [list $colors(line)]
	set flc [list $colors(fill)]
	switch $tool {
	    line { 
		return "line $coords -fill $lnc -width $linewidth"
	    }
	    rectangle {
		return "rectangle $coords -outline $lnc -width $linewidth"
	    }
	    frectangle {
		return "rectangle $coords -fill $flc -outline $lnc -width $linewidth"
	    }
	    oval {
		return "oval $coords -outline $lnc -width $linewidth"
	    }
	    foval {
		return "oval $coords -fill $flc -outline $lnc -width $linewidth"
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
	    set xy [align_line $start_coords(x) $start_coords(y) $x $y]
	    set x [lindex $xy 0]
	    set y [lindex $xy 1]
	}
	if {$shift & 0x4} {
	    set x [align_to_grid_x $x]
	    set y [align_to_grid_y $y]
	}
	if [info exists tempitem] {
	    eval .drawing_canvas.canvas coords $tempitem $coords(x) $coords(y) $x $y]
	} else {
	    set tempitem [eval .drawing_canvas.canvas create [recttool_getdef $x $y]]
	}
    }
    
    proc release {x y shift} {
	variable start_coords
	variable tempitem
	if ![info exists start_coords] {
	    return
	}
	if [info exists tempitem] {
	    unset tempitem
	}
	putsock "GCMD DRAW [recttool_getdef $x $y]" 0
	unset start_coords
    }
}
