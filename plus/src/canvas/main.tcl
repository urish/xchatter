EXTENTION canvas VERSION 1.1 BUILD 6
# $Id: main.tcl,v 1.11 2002-04-01 10:52:49 amirs Exp $

    variable last_active_color
    variable linewidth 1 color
    variable tools
    variable gridsize
    variable canvas_lock "*"
    variable align_angle 22.5
    set gridsize(x) 5
    set gridsize(y) 5
    set tools(list) ""
    
    namespace export	align_to_grid_x \
			align_to_grid_y \
			align_line	\
			putcmd		\
			register_tool

    proc init {} {
	onevent servercmd DRAW [namespace current]::server_cmd_draw
	onevent usercmd CANVAS_LOCK [namespace current]::ucmd_canvas_lock
	iface_init
	canvas_init
	colorbox_init
	linewidth_init
	toolbox_init
    }
    
    proc unload {} {
	unevent servercmd [namespace current]::server_cmd_draw
	unevent usercmd [namespace current]::ucmd_canvas_lock
	destroy .drawing_canvas
    }

    proc iface_init {} {
	toplevel .drawing_canvas
	wm title .drawing_canvas "Drawing Canvas"
	frame .drawing_canvas.topframe
	frame .drawing_canvas.bottomframe
	grid configure .drawing_canvas.topframe -row 1 -column 1 -sticky nswe
	grid configure .drawing_canvas.bottomframe -row 2 -column 1 -sticky wes
	grid columnconfigure .drawing_canvas 1 -weight 1 -minsize 256
	grid rowconfigure .drawing_canvas 1 -weight 2 -minsize 256
	grid rowconfigure .drawing_canvas 2 -weight 0 -minsize 32
    }
        
    proc canvas_init {} {
	canvas .drawing_canvas.canvas -cursor pencil -relief raised -border 2 -height 20 -width 50
	grid configure .drawing_canvas.canvas -in .drawing_canvas.topframe -row 1 -column 1 -sticky nswe
	bind .drawing_canvas.canvas <B1-Motion> "[namespace current]::tool_call motion %x %y %s"
	bind .drawing_canvas.canvas <ButtonPress-1> "[namespace current]::tool_call press %x %y %s"
	bind .drawing_canvas.canvas <ButtonRelease-1> "[namespace current]::tool_call release %x %y %s"
	bind .drawing_canvas.canvas <B3-Motion> "[namespace current]::tool_call rmotion %x %y %s"
	bind .drawing_canvas.canvas <ButtonPress-3> "[namespace current]::tool_call rpress %x %y %s"
	bind .drawing_canvas.canvas <ButtonRelease-3> "[namespace current]::tool_call rrelease %x %y %s"
	grid rowconfigure .drawing_canvas.topframe 1 -weight 1
	grid columnconfigure .drawing_canvas.topframe 1 -weight 1
    }
    
    proc colorbox_init {} {
	variable last_active_color
	variable colors
	frame .drawing_canvas.colorbox -relief raised -border 1
	grid configure .drawing_canvas.colorbox -in .drawing_canvas.bottomframe -row 1 -column 1 -sticky wn
	set counter 0
	foreach i {black white {dark gray} gray {dark blue} blue {dark cyan} cyan {dark red} red {dark orange} orange purple violet {green yellow} yellow {dark green} green} {
	    label .drawing_canvas.colorbox.color#$counter -background $i -height 1 -width 2
	    grid configure .drawing_canvas.colorbox.color#$counter -column [expr $counter / 2] -row [expr $counter % 2] -sticky n
	    bind .drawing_canvas.colorbox.color#$counter <Button-1> "[namespace current]::set_color %W 0"
	    bind .drawing_canvas.colorbox.color#$counter <Button-3> "[namespace current]::set_color %W 1"
	    bind .drawing_canvas.colorbox.color#$counter <Double-Button-1> "[namespace current]::select_color %W"
	    incr counter
	}
	set last_active_color(line) .drawing_canvas.colorbox.color#0
	set last_active_color(fill) .drawing_canvas.colorbox.color#1
	set colors(line) black
	set colors(fill) white
	$last_active_color(line) configure -border 2 -relief raised -text "L" -foreground white
	$last_active_color(fill) configure -border 2 -relief raised -text "F" -foreground black
    }
    
    proc linewidth_init {} {
	variable linewidth_line
	canvas .drawing_canvas.linewbox -relief raised -border 1 -height 36 -width 50
	grid configure .drawing_canvas.linewbox -in .drawing_canvas.bottomframe -row 1 -column 2 -sticky ne
	set linewidth_line [.drawing_canvas.linewbox create line 0 18 30 18 -fill black -width 1]
	set plus [.drawing_canvas.linewbox create polygon 42 1 34 16 50 16 42 1 -fill black]
	set minus [.drawing_canvas.linewbox create polygon 34 20 50 20 42 36 34 20 -fill black]
	.drawing_canvas.linewbox bind all <Any-Enter> "[namespace current]::linewidth_enter"
	.drawing_canvas.linewbox bind all <Any-Leave> "[namespace current]::linewidth_leave"
	.drawing_canvas.linewbox bind $plus <Button-1> "[namespace current]::linewidth_plus"
	.drawing_canvas.linewbox bind $minus <Button-1> "[namespace current]::linewidth_minus"
	set nexty 0
    }
    
    proc register_tool {name namespace icondef} {
	variable tools
	if ![info exists tools(tool)] {
	    set tools(tool) $name
	}
	lappend tools(list) $name
	set tools($name.icondef) $icondef
	set tools($name.namespace) $namespace
    }
    
    proc toolbox_init {} {
	variable tools
	# tool creation
	frame .drawing_canvas.toolbox -relief raised -border 1 -width 200
	grid configure .drawing_canvas.toolbox -in .drawing_canvas.topframe -row 1 -column 2 -sticky e
	set counter 0
	foreach name $tools(list) {
	    set tools($name.id) $counter
	    canvas .drawing_canvas.toolbox.tool#$counter -height 25 -width 25 -border 2
	    grid configure .drawing_canvas.toolbox.tool#$counter -column [expr $counter % 2] -row [expr $counter / 2] -sticky n
	    eval .drawing_canvas.toolbox.tool#$counter create $tools($name.icondef)
	    bind .drawing_canvas.toolbox.tool#$counter <Button-1> "[namespace current]::set_tool $name %W"
	    incr counter
	}
	set tools(prefix) ".drawing_canvas.toolbox.tool#"
	$tools(prefix)$tools($tools(tool).id) configure -relief raised 
    }
    
    proc tool_call {args} {
	variable tools
	set procname [lindex $args 0]
	set args [lrange $args 1 end]
	set proc $tools($tools(tool).namespace)::$procname
	if [llength [info commands $proc]] {
	    eval [list $proc] $args
	}
    }
    
    proc set_tool {tool widget} {
	variable tools
	if {$tool != $tools(tool)} {
	    tool_call deselect
	    $tools(prefix)$tools($tools(tool).id) configure -relief flat
	    set tools(tool) $tool
	    $widget configure -relief raised
	    tool_call select
	}
    }
    
    proc set_color {widget isfill} {
	variable colors
	variable last_active_color
	set kind [expr {$isfill ? "fill" : "line"}]
	set okind [expr {!$isfill ? "fill" : "line"}]
	set names {L F}
	if {$widget != $last_active_color($kind)} {
	    if {$last_active_color($kind) == $last_active_color($okind)} {
		$last_active_color($kind) configure -relief flat -text [lindex $names [expr !$isfill]]
	    } else {
		$last_active_color($kind) configure -relief flat -text ""
	    }
	    set last_active_color($kind) $widget
	    set colors($kind) [$widget cget -background]
	    if {$last_active_color($okind) == $widget} {
		$widget configure -relief raised -text "*"
	    } else {
		$widget configure -relief raised -text [lindex $names $isfill]
	    }
	    set rgb [winfo rgb $widget $colors($kind)]
	    $widget configure -foreground [format "#%04x%04x%04x" [expr 65535 - [lindex $rgb 0]] [expr 65535 - [lindex $rgb 1]] [expr 65535 - [lindex $rgb 2]]]
	}
    }
    
    proc align_to_grid_x {x} {
	variable gridsize
	return [expr round(double($x) / $gridsize(x)) * $gridsize(x)]
    }
    
    proc align_to_grid_y {y} {
	variable gridsize
	return [expr round(double($y) / $gridsize(y)) * $gridsize(y)]
    }
    
    # The following proc was written by doomzday <d00mzy@hotmail.com>
    proc align_line {sx sy ex ey} {
	variable align_angle
	set radius [expr sqrt(abs($sy-$ey)*abs($sy-$ey)+abs($sx-$ex)*abs($sx-$ex))]
	set angle [expr asin(double(abs($ey-$sy)/$radius)) * 180.0 / acos(-1)]
	set bound [expr int($angle / $align_angle) * $align_angle]
	if {$angle - $bound > $bound + $align_angle - $angle} {
	    set bound [expr $bound + $align_angle]
	}
	set addx [expr cos(double($bound*acos(-1)/180))*$radius]
	set addy [expr sin(double($bound*acos(-1)/180))*$radius]
	if {$sx > $ex} {
	    set addx [expr $addx*-1]
	}
	if {$sy > $ey} {
	    set addy [expr $addy*-1]
	}
	return [list [expr round($sx + $addx)] [expr round($sy + $addy)]]
    }
			
    proc select_color {widget} {
	variable colors
	variable last_active_color
	set_color $widget 0
	if {[set colors(line) [tk_chooseColor -parent .drawing_canvas -initialcolor $colors(line) -title "Edit color"]] != ""} {
	    $last_active_color(line) configure -background $colors(line)
	} else {
	    set colors(line) [$last_active_color(line) cget -background]
	}
    }
    
    proc linewidth_enter {} {
	.drawing_canvas.linewbox itemconfigure current -fill red
    }

    proc linewidth_leave {} {
	.drawing_canvas.linewbox itemconfigure current -fill black
    }

    proc linewidth_plus {} {
	variable linewidth
	variable linewidth_line
	if {$linewidth >= 100} {
	    return
	}
        incr linewidth
	.drawing_canvas.linewbox delete $linewidth_line
	set linewidth_line [.drawing_canvas.linewbox create line 0 18 30 18 -fill black -width $linewidth]
    }

    proc linewidth_minus {} {
	variable linewidth
	variable linewidth_line
	if {$linewidth <= 1} {
	    return
	}
	incr linewidth -1
	.drawing_canvas.linewbox delete $linewidth_line
	set linewidth_line [.drawing_canvas.linewbox create line 0 18 30 18 -fill black -width $linewidth]
    }
    
    proc stripslashes {msg} {
	set output ""
	while {[set i [string first "\\" $msg]] > -1} {
	    append output [string range $msg 0 [expr $i - 1]]
	    set buf [string index $msg [expr $i + 1]]
	    set msg [string range $msg [expr $i + 2] end]
	    switch -glob -- $buf {
		\\  {append output \\}
		n   {append output \n}
	    }
	}
	return $output$msg
    }
    
    proc addslashes {string} {
	return [join [split [join [split $string \\] \\\\] \n] \\n]
    }
    
    proc server_cmd_draw {source cargs} {
	variable canvas_lock
	foreach i $canvas_lock {
	    if {[string index $i 0] == "!"} {
	        if [string match [string range $i 1 end] $source] {
		    break
		}
	    } else {
	        if [string match $i $source] {
		    set ok 1
		    break
		}
	    }
	}
	if {![info exists ok] && [string length $canvas_lock]} {
	    return 0
	}
	catch {
	    foreach i $cargs {
	        lappend nargs [stripslashes $i]
	    }
	    eval ".drawing_canvas.canvas create [join $nargs]"
	    return 1
	}
	return 0
    }
    
    proc ucmd_canvas_lock {uargs} {
	variable canvas_lock
	set canvas_lock $uargs
	return 1
    }

    proc putcmd {type coordinates options} {
	putsock "GCMD DRAW $type $coordinates [addslashes $options]" 1
    }

    #########
    # Tools #
    #########
    
    <@INCLUDE rect.tcl>
    <@INCLUDE polygon.tcl>
    <@INCLUDE text.tcl>
    <@INCLUDE zoom.tcl>

