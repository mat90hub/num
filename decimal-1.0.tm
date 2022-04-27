#!/usr/bin/env tclsh
#-*- mode: tcl; coding: utf-8-unix; fill-column: 80; ispell-local-dictionary: "american"; -*-

#╔════════════════════════╗
#║ *** decimal-1.0.tm *** ║
#╚════════════════════════╝

package provide decimal 1.0

# ----------------------------------------------------------------------------------
# This package manages decimals represented in a particular local: it helps
# conversion between decimals using the locals and tcl float.
# Typically used of ',' or '.' and space of ',' for thousands
# ----------------------------------------------------------------------------------

# Principal commands for practical use:
# -------------------------------------
# decimal format $data           : format a tcl float to a decimal
# decimal null                   : return the null decimal
# decimal is formatted $data     : return t is $data is a decimal
# decimal to double $data        : convert a decimal to tcl double
# decimal add $data1 $data2      : add two decimals
# decimal byCoef $coef $data     : mulitply a decimal by a double coef
# decimal subFrom $data1 $data2  : sub $data2 to $data1


# Commands to regulate the package behavior
# -----------------------------------------
# decimal get locale

# decimal get decimalSep $data
# decimal get thousandSep $data
# decimal get accuracy $data

# decimal set decimalSep $data
# decimal set thousandSep $data
# decimal set accuracy $data

# ----------------------------------------------------------------------------------

namespace eval decimal {

    namespace export *
    namespace ensemble create

    variable decimalSep "," thousandSep " " accuracy 2

    # ------------------------------------------------------------------------------
    #  decimal style $data
    # ------------------------------------------------------------------------------
    # recognize the style of decimal and update variable in this package
    # ------------------------------------------------------------------------------
    proc style data {
	variable decimalSep
	variable thousandSep
	
	if [string is integer $data] {
	    error "cannot recognize decimal style with an integer"
	}
	# tcl style 
	if [string is double $data] {	    
	    set decimalSep "."
	    set thousandSep ""	    
	    return Tcl_style
	}
	# French style
	if [string is double [string map {"," "." " " ""} $data]] {
	    set decimalSep ","
	    set thousandSep " "
	    return French_style
	}
	if [string is double [string map {"," ""} $data]] {
	    set decimalSep "."
	    set thousandSep ","
	    return US_style
	}
	error "no recognition done, is $data a decimal ?"
    }
    # ------------------------------------------------------------------------------

    
    namespace eval get {

	namespace export *
	namespace ensemble create

	# --------------------------------------------------------------------------
	# decimal get locale
	# --------------------------------------------------------------------------
	# get the decimal separator and thousand separators from locale settings
	# --------------------------------------------------------------------------
	proc locale {} {
	    variable ::decimal::decimalSep
	    variable ::decimal::thousandSep
	    
	    foreach line [exec locale -k LC_NUMERIC] {
		set L [string map {= \ } $line]
		switch [lindex $L 0] {
		    "decimal_point" {set ::decimal::decimalSep [lindex $L 1]}
		    "thousands_sep" {set ::decimal::thousands_sep [lindex $L 1]}
		}
	    }
	    return [list decimal_point $::decimal::decimalSep \
			thousands_sep $::decimal::thousands_sep]
	}
	# --------------------------------------------------------------------------

	
	# --------------------------------------------------------------------------
	# decimal get decimalSep
	# --------------------------------------------------------------------------
	# return the current decimal separator
	# --------------------------------------------------------------------------
	proc decimalSep {} {
	    variable ::decimal::decimalSep
	    return $::decimal::decimalSep
	}	
	# --------------------------------------------------------------------------

	# --------------------------------------------------------------------------
	# decimal get thousandSep
	# --------------------------------------------------------------------------
	# return the current thousand separator
	# --------------------------------------------------------------------------
	proc thousandSep {} {
	    variable ::decimal::thousandSep
	    return $::decimal::thousandSep
	}	
	# --------------------------------------------------------------------------

	# --------------------------------------------------------------------------
	# decimal get accuracy
	# --------------------------------------------------------------------------
	# return the default number of digits after decimal separator
	# --------------------------------------------------------------------------
	proc accuracy {} {
	    variable ::decimal::accuracy
	    return $::decimal::accuracy
	}	
	# --------------------------------------------------------------------------
	
    }

    namespace eval set {

	namespace export *
	namespace ensemble create
	       
	# --------------------------------------------------------------------------
	# decimal set decimalSep
	# --------------------------------------------------------------------------
	# set the decimal separator
	# --------------------------------------------------------------------------
	proc decimalSep data {
	    variable ::decimal::decimalSep
	    set ::decimal::decimalSep $data
	    return $::decimal::decimalSep
	}	
	# --------------------------------------------------------------------------

	# --------------------------------------------------------------------------
	# decimal set thousandSep
	# --------------------------------------------------------------------------
	# set the thousand separator
	# --------------------------------------------------------------------------
	proc thousandSep data {
	    variable ::decimal::thousandSep
	    set ::decimal::thousandSep $data 
	    return $::decimal::thousandSep
	}	
	# --------------------------------------------------------------------------

	# --------------------------------------------------------------------------
	# decimal set accuracy
	# --------------------------------------------------------------------------
	# set the default number of digits after decimal separator
	# --------------------------------------------------------------------------
	proc accuracy data {
	    variable ::decimal::accuracy
	    set ::decimal::accuracy $data 
	    return $::decimal::accuracy
	}	
	# --------------------------------------------------------------------------

    }
    
    namespace eval from {
	namespace export double
	namespace ensemble create

	# -------------------------------------------------------------------------
	# decimal from double $data
	# -------------------------------------------------------------------------
	# Format the string $data representing a double in a formated decimal
	# -------------------------------------------------------------------------
	proc double data {
	    variable ::decimal::decimalSep
	    variable ::decimal::thousandSep
	    variable ::decimal::accuracy
	    
	    if {$data eq "" } {return}
	    if ![string is double $data] {return $data}
	    
	    # set accuracy to 2
	    set data [::format [join "%. $::decimal::accuracy f" ""] $data]
	    
	    # Set apart the WHOLE part from the DECIMAL part.
	    set PNTPOS [string first . $data]
	    if {$PNTPOS != -1} {
		set WHL [string range $data 0 [expr $PNTPOS -1]]
		if {[string length $WHL] == 0} {set WHL 0}
		set DEC [string range $data $PNTPOS+1 end]
	    } else {
		# data is an integer
		set WHL $data
		set DEC "00"
	    }
	    
	    set data $WHL$::decimal::decimalSep$DEC
	    
	    # Insert thousand separator every 3 characters
	    while {[regsub {^([-+]?\d+)(\d\d\d)} $data "\\1$::decimal::thousandSep\\2" data]} {}

	    return $data	    
	}
	# --------------------------------------------------------------------------	
    }
    
    # -------------------------------------------------------------------------------
    # decimal format $data
    # -------------------------------------------------------------------------------
    # short cut for `decimal from double $data`
    # -------------------------------------------------------------------------------
    proc format data {
	return [from double $data]
    }
    # -------------------------------------------------------------------------------

    
    # ------------------------------------------------------------------------------
    # decimal null
    # ------------------------------------------------------------------------------
    # return the null decimal
    # ------------------------------------------------------------------------------
    proc null {} {
	return [from double 0]
    }
    # ------------------------------------------------------------------------------

    
    namespace eval is {
	namespace export formatted
	namespace ensemble create
    
	# ------------------------------------------------------------------------------
	# decimal is formatted $data
	# ------------------------------------------------------------------------------
	# return true if $data is recognized as a decimal string.
	# ------------------------------------------------------------------------------
	proc formatted data {
	    variable ::decimal::decimalSep
	    variable ::decimal::thousandSep

	    set data [string trim $data] 
	    
	    # remove thousand Sep and change decimal sep and check if it is a number
	    # -------------------------------------------------------------------------
	    regsub $::decimal::thousandSep $data "" data
	    if {$::decimal::decimalSep ne "."} {regsub $::decimal::decimalSep $data "." data}
	    
	    if [string is double $data] {return true} {return false}	
	    
	}
	# regex to recognize a French Integer:
	# regexp {^([+-]\s?)?(((\d{1,3}\s)*\d{3})|\d{1,3})$} $data ->
	#
	# regex to recognize a US Integer:
	# regexp {^([+-]\s?)?(((\d{1,3},)*\d{3})|\d{1,3})$} $data ->
	# ------------------------------------------------------------------------------
    }

    namespace eval to {
	namespace export double
	namespace ensemble create
	
	#------------------------------------------------------------------------------
	# decimal to double $data
	#------------------------------------------------------------------------------
	# Input is a formatted string.
	#------------------------------------------------------------------------------
	# Reverse operation of `decimal from $data`.
	# Note that parameter must be protected (as example by "") to avoid that
	# the blank separating the thousands would be interpreted as separation
	# between parameters.
	#------------------------------------------------------------------------------
	proc double data {
	    variable ::decimal::decimalSep
	    variable ::decimal::thousandSep

	    if {[string length $data] == 0} {return 0}	    	    

	    # remove thousand separator and put point as decimal separator
	    regsub -all $::decimal::thousandSep $data "" data
	    if {$::decimal::decimalSep ne "."} {regsub $::decimal::decimalSep $data "." data}
	    
	    return $data
	}
	#------------------------------------------------------------------------------
    }
	
    #------------------------------------------------------------------------------
    # decimal add $data1 $data2
    #------------------------------------------------------------------------------
    proc add {data1 data2} {
	return [from double [expr [to double $data1] + [to double $data2]]]
    }
    #------------------------------------------------------------------------------

    #------------------------------------------------------------------------------
    # decimal byCoef $data1 $data2
    #------------------------------------------------------------------------------
    # multiply decimal by a coefficient (a double)
    #------------------------------------------------------------------------------
    proc byCoef {coef data} {
	return [from double [expr $coef * [to double $data]]]
    }
    #------------------------------------------------------------------------------

    #------------------------------------------------------------------------------
    # decimal subFrom $data1 $data2
    #------------------------------------------------------------------------------
    proc subFrom {data1 data2} {
	return [from double [expr [to double $data1] - [to double $data2]]]	
    }
    #------------------------------------------------------------------------------
}
#----------------------------------------------------------------------------------

