#!/usr/bin/env tclsh
#-*- mode: tcl; coding: utf-8-unix; fill-column: 80; ispell-local-dictionary: "american"; -*-

#╔═══════════════════════╗
#║ *** amount-1.0.tm *** ║
#╚═══════════════════════╝

package provide amount 1.0

#----------------------------------------------------------------------------------
# This package manages financial amounts : it helps converting a string representing
# a double into a currency representing an amount with the correct representation.
# Currency and other typo (coma) are namespace variables, which can be updated.
#----------------------------------------------------------------------------------
namespace eval amount {

    namespace export *
    namespace ensemble create

    variable currency "€" decimalSep "," thousandSep " " currencyAfterValue true fmtStr %14s


    namespace eval get {

	namespace export *
	namespace ensemble create
	
	#--------------------------------------------------------------------------
	# amount get currency
	#--------------------------------------------------------------------------
	# return the currency symbol
	#--------------------------------------------------------------------------
	proc currency {} {
	    variable ::amount::currency
	    return $::amount::currency
	}
	#--------------------------------------------------------------------------

	#--------------------------------------------------------------------------
	# amount get decimalSep
	#--------------------------------------------------------------------------
	# return the current decimal separator
	#--------------------------------------------------------------------------
	proc decimalSep {} {
	    variable ::amount::decimalSep
	    return $decimalSep
	}	
	#--------------------------------------------------------------------------

	#--------------------------------------------------------------------------
	# amount get thousandSep
	#--------------------------------------------------------------------------
	# return the current thousand separator
	#--------------------------------------------------------------------------
	proc thousandSep {} {
	    variable ::amount::thousandSep
	    return $::amount::thousandSep
	}	
	#--------------------------------------------------------------------------

	#--------------------------------------------------------------------------
	# amount get currencyAfterValue
	#--------------------------------------------------------------------------
	# return true if currency is shown after value
	#--------------------------------------------------------------------------
	proc currencyAfterValue {} {
	    variable ::amount::currencyAfterValue
	    return $::amount::currencyAfterValue
	}
	#--------------------------------------------------------------------------

	#--------------------------------------------------------------------------
	# amount get fmtStr ?data?
	#--------------------------------------------------------------------------
	# get the fmtStr stored in the name space.
	# If a data is given, return the recognized formatting string
	#--------------------------------------------------------------------------
	proc fmtStr {{data {}}} {
	    variable ::amount::fmtStr
	    if {[string length $data] == 0} {
		return $::amount::fmtStr
	    } {
		set L [string length $data]
		# check if some blank before or after
		if {[lindex $data end] ne " "} {
		    set ::amount::fmtStr [join "% $L s" ""]
		} {
		    set ::amount::fmtStr [join "% - $L s" ""]
		}
	    }
	}
	#--------------------------------------------------------------------------
    }

    namespace eval set {

	namespace export *
	namespace ensemble create
	
	#--------------------------------------------------------------------------
	# amount set currency
	#--------------------------------------------------------------------------
	# set the currency symbol
	#--------------------------------------------------------------------------
	proc currency data {
	    variable ::amount::currency
	    set ::amount::currency $data
	    return $::amount::currency
	}
	#--------------------------------------------------------------------------

	#--------------------------------------------------------------------------
	# amount set decimalSep
	#--------------------------------------------------------------------------
	# set the decimal separator
	#--------------------------------------------------------------------------
	proc decimalSep data {
	    variable ::amount::decimalSep
	    set ::amount::decimalSep $data
	    return $::amount::decimalSep
	}	
	#--------------------------------------------------------------------------

	#--------------------------------------------------------------------------
	# amount set thousandSep
	#--------------------------------------------------------------------------
	# set the thousand separator
	#--------------------------------------------------------------------------
	proc thousandSep data {
	    variable ::amount::thousandSep
	    set ::amount::thousandSep $data 
	    return $::amount::thousandSep
	}	
	#--------------------------------------------------------------------------

	#--------------------------------------------------------------------------
	# amount set currencyAfterValue ?true/false?
	#--------------------------------------------------------------------------
	# set the currency after the value
	#--------------------------------------------------------------------------
	proc currencyAfterValue {{data {}}} {
	    variable ::amount::currencyAfterValue
	    if {[llength $data] == 0} {set data true}
	    if {$data eq true || $data eq false} {
		set ::amount::currencyAfterValue $data
		return $::amount::currencyAfterValue
	    } {
		error "amount set currencyAfterValue true or false"
	    }
	}
	#--------------------------------------------------------------------------

	#--------------------------------------------------------------------------
	# amount set currencyBeforeValue ?true/false?
	#--------------------------------------------------------------------------
	# set the currency before the value
	#--------------------------------------------------------------------------
	proc currencyBeforeValue {{data {}}} {
	    variable ::amount::currencyAfterValue
	    if {[llength $data] == 0} {set data false}
	    switch [string tolower $data] {
		false {set ::amount::currencyAfterValue true}
		true {set ::amount::currencyAfterValue false}
		default {error "amount set currencyBeforeValue true or false"}
	    }
	    set ::amount::currencyAfterValue $data
	    return $::amount::currencyAfterValue
	}
	#--------------------------------------------------------------------------

	#--------------------------------------------------------------------------
	# amount set fmtStr
	#--------------------------------------------------------------------------
	proc fmtStr data {
	    variable ::amount::fmtStr	    
	    if ![string is integer [string trimright [string trimleft $data %] s]] {
		error "amount formatting string must of the form %15s or %-15s"
	    }	    
	    set ::amount::fmtStr $data
	    return $::amount::fmtStr
	}
	#--------------------------------------------------------------------------
    }
    
    #------------------------------------------------------------------------------
    # amount null
    #------------------------------------------------------------------------------
    # return the null amount
    #------------------------------------------------------------------------------
    proc null {} {
	variable ::amount::currency
	variable ::amount::decimalSep
	variable ::amount::currencyAfterValue

	if $::amount::currencyAfterValue {
	    return [join [list [join [list 0 $::amount::decimalSep 00] ""] $::amount::currency]]
	} {
	    return [join [list $::amount::currency [join [list 0 $::amount::decimalSep 00] ""]]]
	}
    }
    #------------------------------------------------------------------------------

    namespace eval from {
	namespace export double
	namespace ensemble create

	#-------------------------------------------------------------------------
	# amount from double $data
	#-------------------------------------------------------------------------
	# Format the string $data representing a double in a formated amount
	#-------------------------------------------------------------------------
	proc double data {
	    variable ::amount::currency
	    variable ::amount::decimalSep
	    variable ::amount::thousandSep
	    variable ::amount::currencyAfterValue
	    
	    if {$data eq "" } {return}
	    if ![string is double $data] {return $data}
	    
	    # set accuracy to 2
	    set data [::format %.2f $data]
	    
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
	    
	    set data $WHL$::amount::decimalSep$DEC
	    
	    # Insert thousand separator every 3 characters
	    while {[regsub {^([-+]?\d+)(\d\d\d)} $data "\\1$::amount::thousandSep\\2" data]} {}
	    
	    # add the currency symbol
	    if $::amount::currencyAfterValue {
		return "$data $::amount::currency"
	    } {
		return "$::amount::currency $data"
	    }
	}
	#--------------------------------------------------------------------------	
    }
    

    namespace eval is {
	namespace export formatted
	namespace ensemble create
    
	#------------------------------------------------------------------------------
	# amount is formatted $data
	#------------------------------------------------------------------------------
	# return true if $data is a recognized as a string representing an amount.
	#------------------------------------------------------------------------------
	proc formatted data {
	    variable ::amount::currency
	    variable ::amount::decimalSep
	    variable ::amount::thousandSep
	    variable ::amount::currencyAfterValue

	    set data [string trim $data] 
	    
	    # 1) check currency
	    # -----------------
	    set POS [string first $::amount::currency $data]

	    if {$POS == -1} {return false}
	    # return false if currency is not at the good position
	    if {$POS == 0 && $::amount::currencyAfterValue} {return false}

	    set LEN [string length $::amount::currency]
	    if {[expr $POS + $LEN] == [string length $data]} {
		if !$::amount::currencyAfterValue {return false}
	    } {
		return false
	    }

	    if {$POS == 0} {
		set data [string trimleft [string range $data $LEN end]]
	    } {
		set data [string trimright [string range $data 0 $POS-1]]
	    }

	    # 2) remove thousand Sep and change decimal sep and check if it is a number
	    # -------------------------------------------------------------------------
	    regsub $::amount::thousandSep $data "" data
	    if {$::amount::decimalSep ne "."} {regsub $::amount::decimalSep $data "." data}
	    
	    if [string is double $data] {return true} {return false}	
	    
	}
	#------------------------------------------------------------------------------
    }

    namespace eval to {
	namespace export double
	namespace ensemble create
	
	#------------------------------------------------------------------------------
	# amount to double $data
	#------------------------------------------------------------------------------
	# Input is a string formatted with format€ to obtain a float.
	#------------------------------------------------------------------------------
	# Reverse operation of format€.
	# Note that parameter must be protected (as example by "") to avoid that
	# the blank separating the thousands would be interpreted as separation
	# between parameters.
	#------------------------------------------------------------------------------
	# set $data [string map [subst {\\$sep "" € "" $dec . }]  $str]
	proc double data {
	    variable ::amount::currency
	    variable ::amount::decimalSep
	    variable ::amount::thousandSep
	    variable ::amount::currencyAfterValue

	    if {[string length $data] == 0} {return 0}
	    
	    set LEN [string length $::amount::currency]

	    # remove currency
	    if $::amount::currencyAfterValue {
		set data [string trimright [string range $data 0 end-$LEN]]
	    } {
		set data [string trimleft [string range $data $LEN end]]
	    }

	    # remove thousand separator and put point as decimal separator
	    regsub -all $::amount::thousandSep $data "" data
	    if {$::amount::decimalSep ne "."} {regsub $::amount::decimalSep $data "." data}
	    
	    return $data
	}
	#------------------------------------------------------------------------------
    }
	
    #------------------------------------------------------------------------------
    # amount add $data1 $data2
    #------------------------------------------------------------------------------
    proc add {data1 data2} {
	return [from double [expr [to double $data1] + [to double $data2]]]	
    }
    #------------------------------------------------------------------------------

    #------------------------------------------------------------------------------
    # amount byCoef $data1 $data2
    #------------------------------------------------------------------------------
    # multiply amount by a coefficient (a double)
    #------------------------------------------------------------------------------
    proc byCoef {coef data} {
	return [from double [expr $coef * [to double $data]]]
    }
    #------------------------------------------------------------------------------

    #------------------------------------------------------------------------------
    # amount subFrom $data1 $data2
    #------------------------------------------------------------------------------
    proc subFrom {data1 data2} {
	return [from double [expr [to double $data1] - [to double $data2]]]
    }
    #------------------------------------------------------------------------------
}
#----------------------------------------------------------------------------------
