# $Id: text.tcl,v 1.2 2002-03-31 19:15:39 amirs Exp $

namespace eval texttool {
    namespace import    [namespace parent]::putcmd
    # register tools
    variable font {-family times -size 12}
    variable shape ""

    proc textInsert {w tag string} {
        if {$string == ""} {
    	    return
        }
        catch {$w dchars $tag sel.first sel.last}
        $w insert $tag insert $string
    }

    proc textPaste {w tag pos} {
        catch {
    	    $w insert $tag $pos [selection get]
        }
    }

    proc textB1Press {w tag x y} {
        $w icursor current @$x,$y
        $w focus current
        focus $w
        $w select from current @$x,$y
    }
    
    proc textB1Move {w tag x y} {
        $w select to current @$x,$y
    }
    
    proc textBs {w tag} {
        if ![catch {$w dchars $tag sel.first sel.last}] {
    	    return
        }
        set char [expr {[$w index $tag insert] - 1}]
        if {$char >= 0} {$w dchar $tag $char}
    }
    
    proc textDel {w tag} {
        if ![catch {$w dchars $tag sel.first sel.last}] {
    	    return
        }
        $w dchars $tag insert
    }

    proc end_textbox {} {
	variable shape
	if {$shape != ""} { 
	    .drawing_canvas.canvas bind $shape <1> 		""
	    .drawing_canvas.canvas bind $shape <B1-Motion> 	""
	    .drawing_canvas.canvas bind $shape <Shift-1> 		""
	    .drawing_canvas.canvas bind $shape <Shift-B1-Motion> 	""
	    .drawing_canvas.canvas bind $shape <KeyPress> 		""
	    .drawing_canvas.canvas bind $shape <Return> 		""
	    .drawing_canvas.canvas bind $shape <Control-h> 	""
	    .drawing_canvas.canvas bind $shape <BackSpace> 	""
	    .drawing_canvas.canvas bind $shape <Delete> 		""
	    .drawing_canvas.canvas bind $shape <2> 		""
	    set text [.drawing_canvas.canvas itemcget $shape -text]
	    if {[string trim $text] == ""} {
	        .drawing_canvas.canvas delete $shape
	    } else {
	        putcmd "text [.drawing_canvas.canvas coords $shape] [list -text $text] [list -fill [.drawing_canvas.canvas itemcget $shape -fill]] [list -anchor [.drawing_canvas.canvas itemcget $shape -anchor]] [list -font [.drawing_canvas.canvas itemcget $shape -font]]" 0
	    }
	    set shape ""
	}
    }

    proc start_textbox {x y} {
	variable shape
	variable font
	if {$shape == ""} {
	    set shape [.drawing_canvas.canvas create text $x $y -text "" -width 440 -anchor n -font $font -justify left -fill [set [namespace parent]::colors(line)]]
	}
	.drawing_canvas.canvas bind $shape <1> 		"[namespace current]::textB1Press .drawing_canvas.canvas $shape %x %y"
	.drawing_canvas.canvas bind $shape <B1-Motion> 	"[namespace current]::textB1Move .drawing_canvas.canvas $shape %x %y"
	.drawing_canvas.canvas bind $shape <Shift-1> 		".drawing_canvas.canvas select adjust current @%x,%y"
	.drawing_canvas.canvas bind $shape <Shift-B1-Motion> 	"[namespace current]::textB1Move .drawing_canvas.canvas $shape %x %y"
	.drawing_canvas.canvas bind $shape <KeyPress> 		"[namespace current]::textInsert .drawing_canvas.canvas $shape %A"
	.drawing_canvas.canvas bind $shape <Return> 		"[namespace current]::textInsert .drawing_canvas.canvas $shape \\n"
	.drawing_canvas.canvas bind $shape <Control-h> 	"[namespace current]::textBs .drawing_canvas.canvas $shape"
	.drawing_canvas.canvas bind $shape <BackSpace> 	"[namespace current]::textBs .drawing_canvas.canvas $shape"
	.drawing_canvas.canvas bind $shape <Delete> 		"[namespace current]::textDel .drawing_canvas.canvas $shape"
	.drawing_canvas.canvas bind $shape <2> 		"[namespace current]::textPaste .drawing_canvas.canvas $shape @%x,%y" 

	.drawing_canvas.canvas focus $shape
	focus .drawing_canvas.canvas
    }

    proc setcolor {line fill} {
	variable shape
	.drawing_canvas.canvas itemconfigure $shape -fill $line
    }
    
    proc press {x y shift} {
	variable coords
	variable shape
	end_textbox	    
	set coords(x) $x
	set coords(y) $y
    }
    
    proc release {x y shift} {
	variable coords
	variable shape
	end_textbox
	if {$shift & 0x1} {
	    set shape ""
	} elseif {[.drawing_canvas.canvas type current] == "text"} {
	    set shape [.drawing_canvas.canvas find withtag current]
	} else {
	    set shape ""
	}

	start_textbox $coords(x) $coords(y)
	unset coords
    }
    
    proc rpress {x y shift} {
	end_textbox
    }
    
    proc deselect {} {
	end_textbox
	.drawing_canvas.canvas focus ""
	focus .drawing_canvas.canvas
    }

    proc select {} {
	variable font
	font_dialog .font_dialog $font font_selected
    }
    
    proc font_selected {newfont} {
	variable font
	variable shape
	if {$font != $newfont} {
	    set font $newfont
	    .drawing_canvas.canvas itemconfigure $shape -font $font
	}
    }

    # Font selection dialog
    proc font_dialog {base font callback} {
	global font_dialog_example font_dialog_font_size font_dialog_font_style
	set font_dialog_example "example"
	if [llength [info commands $base]] {
	    raise $base
	    focus $base
	    return
	}
        set fspos [lsearch $font "-size"]
	set ffpos [lsearch $font "-family"]
	set bdpos [lsearch $font "-weight"]
	set ulpos [lsearch $font "-underline"]
	set itpos [lsearch $font "-slant"]
        if {$fspos != -1} {
	    set size [lindex $font [expr $fspos + 1]]
	} else {
	    set size 12
	}
	set bold [expr {[lindex $font [expr $bdpos + 1]] == "bold"}]
	set uline [expr {[lindex $font [expr $ulpos + 1]] == "1"}]
	set italic [expr {[lindex $font [expr $itpos + 1]] == "italic"}]
	set families [lsort [font families]]
	set family 0
	if {$ffpos != -1} {
	    set familyname [lindex $font [expr $ffpos + 1]]
	    set family [lsearch $families $familyname]
	    if {$family == -1} {
		set family 0
	    }
	}
	toplevel $base
	wm title $base "Font select"
	frame $base.fontopts -relief raised
        frame $base.family -relief raised
        frame $base.size -relief raised
        frame $base.buttons -relief raised
	frame $base.example -relief raised
        label $base.family.label -text "Family:"
        listbox $base.family.list -yscrollcommand "$base.family.scroll set" -width 0
	bind $base.family.list <1> [list [namespace current]::font_dialog_update_example $base]
	bind $base.family.list <Key> [list [namespace current]::font_dialog_update_example $base] 
        scrollbar $base.family.scroll -command "$base.family.list yview"
        label $base.size.label -text "Size:"
        scale $base.size.scale -showvalue 1 -from 8 -to 72 -variable font_dialog_font_size -orient vertical
	trace variable font_dialog_font_size w [format {
	    %s::font_dialog_update_example [list %s]
	} [namespace current] [list $base]]
	button $base.size.bold -text "Bold" -command [list [namespace current]::font_dialog_toggle_style $base 0 bold]
	button $base.size.underline -text "ULine" -command [list [namespace current]::font_dialog_toggle_style $base 1 underline]
	button $base.size.italic -text "Italic" -command [list [namespace current]::font_dialog_toggle_style $base 2 italic]
	if $bold {
	    $base.size.bold configure -relief sunken
	}
	if $uline {
	    $base.size.underline configure -relief sunken
	}
	if $italic {
	    $base.size.italic configure -relief sunken
	}
	set font_dialog_font_style [list $bold $uline $italic]
        button $base.buttons.ok -text "Ok" -command [list [namespace current]::font_dialog_ok $base $callback]
        button $base.buttons.cancel -text "Cancel" -command [list [namespace current]::font_dialog_cancel $base $callback $font]
        button $base.buttons.apply -text "Apply" -command [list [namespace current]::font_dialog_apply $base $callback]
        label $base.example.label -text "Example:"
        entry $base.example.entry -textvariable font_dialog_example -font $font -width 0
        pack $base.fontopts
        eval $base.family.list insert end $families
        $base.family.list selection anchor $family
        $base.family.list selection set $family
        $base.family.list see $family
	pack $base.example -fill x
	pack $base.example.label -side left
	pack $base.example.entry -side left -fill x
        pack $base.family -in $base.fontopts -side left
        pack $base.family.label -anchor w
        pack $base.family.list -side left
        pack $base.family.scroll -side left -fill y
        pack $base.size -in $base.fontopts -side left -anchor n
        pack $base.size.label -anchor w
        pack $base.size.scale -fill y
	pack $base.size.bold -fill y
	pack $base.size.underline -fill y
	pack $base.size.italic -fill y
	pack $base.example.label -anchor w
        pack $base.buttons.ok -side left
        pack $base.buttons.cancel -side left
        pack $base.buttons.apply -side left
        pack $base.buttons
    }

    proc font_dialog_get_font {base} {
	global font_dialog_font_size font_dialog_font_style
	set result [list -family [$base.family.list get anchor] -size $font_dialog_font_size]
	if [lindex $font_dialog_font_style 0] {
	    lappend result -weight bold
	}
	if [lindex $font_dialog_font_style 1] {
	    lappend result -underline 1
	}
	if [lindex $font_dialog_font_style 2] {
	    lappend result -slant italic
	}
	return $result
    }
    
    proc font_dialog_update_example {base} {
        $base.example.entry configure -font [font_dialog_get_font $base]
    }

    proc font_dialog_ok {base callback} {
        global font_dialog_font_size
        $callback [font_dialog_get_font $base]
        destroy $base
    }

    proc font_dialog_cancel {base callback font} {
        $callback $font
        destroy $base
    }

    proc font_dialog_apply {base callback} {
        global font_dialog_font_size
        $callback [font_dialog_get_font $base]
    }
    
    proc font_dialog_toggle_style {base style name} {
	global font_dialog_font_style
	set newval [expr ![lindex $font_dialog_font_style $style]]
	set font_dialog_font_style [lreplace $font_dialog_font_style $style $style $newval]
	$base.size.$name configure -relief [expr {$newval ? "sunken" : "raised"}]
	font_dialog_update_example $base
    }
}
