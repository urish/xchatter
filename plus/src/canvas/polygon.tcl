# $Id: polygon.tcl,v 1.6 2002-04-01 10:39:20 amirs Exp $

# polygons (multi-line based tools)
namespace eval polygon {
    namespace import	[namespace parent]::align_to_grid_x	\
			[namespace parent]::align_to_grid_y	\
			[namespace parent]::align_line		\
			[namespace parent]::putcmd		\
			[namespace parent]::register_tool
    
    register_tool polygon	polygon {polygon 4 4 4 22 22 25 22 4 14 16 -outline black -fill ""}
    register_tool fpolygon	polygon {polygon 4 4 4 22 22 25 22 4 14 16 -outline black -fill white}
    register_tool cpolygon	polygon {polygon 4 4 4 22 22 25 22 4 14 16 -outline black -fill "" -smooth 1}
    register_tool cfpolygon	polygon {polygon 4 4 4 22 22 25 22 4 14 16 -outline black -fill white -smooth 1}

    proc press {x y shift} {
	variable coords
	variable tempitem
	if {$shift & 0x1} {
	    set xy [align_line $coords(x) $coords(y) $x $y]
	    set x [lindex $xy 0]
	    set y [lindex $xy 1]
	}
	if {$shift & 0x4} {
	    lappend coords [align_to_grid_x $x] [align_to_grid_y $y]
	} else {
	    lappend coords $x $y
	}
	if ![info exists tempitem] {
	    if {[string index [set [namespace parent]::tools(tool)] 0] == "c"} {
    		set tempitem [eval .drawing_canvas.canvas create line $coords $coords -smooth 1]
	    } else {
    		set tempitem [eval .drawing_canvas.canvas create line $coords $coords]
	    }
	} else {
	    eval .drawing_canvas.canvas coords $tempitem $coords
	}
    }
    
    proc getdef {coords} {
	set lnc [list [set [namespace parent]::colors(line)]]
	set flc [list [set [namespace parent]::colors(fill)]]
	set lnwidth [set [namespace parent]::linewidth]
	switch [set [namespace parent]::tools(tool)] {
	    polygon { 
		return "polygon $coords -outline $lnc -width $lnwidth -fill {}"
	    }
	    fpolygon {
		return "polygon $coords -outline $lnc -width $lnwidth -fill $flc"
	    }
	    cpolygon { 
		return "polygon $coords -outline $lnc -width $lnwidth -fill {} -smooth 1"
	    }
	    cfpolygon {
		return "polygon $coords -outline $lnc -width $lnwidth -fill $flc -smooth 1"
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
	eval .drawing_canvas.canvas coords $tempitem $coords $x $y
    }
    
    proc rpress {x y shift} {
	deselect	
    }
        
    proc deselect {} {
	variable coords
	variable tempitem
	if ![info exists coords] {
	    return
	}
	if {[llength $coords] >= 6} {
	    .drawing_canvas.canvas delete $tempitem
	    set def [getdef $coords]
	    eval .drawing_canvas.canvas create $def
	    putcmd "$def"
	}
	unset coords
	unset tempitem
    }
}
