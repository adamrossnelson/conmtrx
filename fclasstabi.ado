*! NEW DEV . . .
*! 2.0.1 Ariel Linden 05oct2017 // accepted edits by NJC                                                                       
*! 2.0.0 Ariel Linden 03oct2017 // fixed bug occurring when cell value is 0
								// fixed output label for "correctly classified"
								// Nicholas J Cox supplied the code to accept matrix arguments
*! 1.0.1 Ariel Linden 13jan2016 // changed rowname and colname to rowlab and collab to represent labels instead of var names
*! 1.0.0 Ariel Linden 27dec2015 

capture program drop fclasstabi
program define fclasstabi, rclass byable(recall)
	// Version control
	version 15

	// Syntax statement limits first argument to variable name which must be
	// binary. Subsequent arguments varlist of one or more vars which also must
	// be binary. Includes support for if and in qualifiers.
	syntax varlist(min=2 numeric) [if] [in] [,NOPrint FORmat(passthru) MATrix(string)]

	// Tag subsample with temp var touse & test if empty.
	marksample touse
	quietly count if `touse'
	if `r(N)' == 0 {
		di as error "ERROR: No observations after if or in qualifier."
		error 2000
	}

	// Test number of arguments. Must be at least two.
	local nvar : word count `varlist'
	if `nvar' < 2 {
		di as error "ERROR: Too few arguments specified."
		error 102
	}

	// Test that arguments are binary.
	foreach v of varlist `varlist' {
		capture assert `v' == 1 | `v' == 0
		if _rc {
			di as error "ERROR: Variable `v' not binary. Values must be 0 or 1."
			error 452
		}
	}

end

