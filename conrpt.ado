*! NEW DEV . . .

capture program drop conrpt
program define conrpt, rclass byable(recall)
	// Version control
	version 15

	// Syntax statement limits first argument to variable name which must be
	// binary. Subsequent arguments varlist of one or more vars which also must
	// be binary. Includes support for if and in qualifiers.
	syntax varlist(min=2 numeric) [if] [in] [,NOPrint FORmat(passthru) MATrix(string)]
	
	local sp char(13) char(10) // Define spacer.

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
	
	// Model table template
	// | testname    | actual neg  | actual pos  | true neg    | false pos   | 
	// |             | tested neg  | tested pos  | false neg   | true pos    |

    // ObservedNeg
	// ObservedPos
	// TestedNeg
	// TestedPos
	// TrueNeg
	// FalsePos
	// FalseNeg
	// FalsePos



	// Build Matricies
	local varlist2 =  substr("`varlist'",strpos("`varlist'"," "),strlen("`varlist'") - strpos("`thelist'"," "))
	foreach v of varlist `varlist2' {
		tempname rmat_`v'
		matrix `rmat'_`v' = J(2, 4,.)
		local i 1
		
		qui {
			count if `1' == 0 & `touse'
			matrix `rmat'_`v'[`i',1] = r(N)
			count if `1' == 1 & `touse'
			matrix `rmat'_`v'[`i',2] = r(N)
			count if `v' == 0 & `1' == 0 & `touse'
			matrix `rmat'_`v'[`i',3] = r(N)
			count if `v' == 1 & `1' == 0 & `touse'
			matrix `rmat'_`v'[`i',4] = r(N)
			local ++i
			count if `v' == 0 & `touse'
			matrix `rmat'_`v'[`i',1] = r(N)
			count if `v' == 1 & `touse'
			matrix `rmat'_`v'[`i',2] = r(N)
			count if `v' == 0 & `1' == 1 & `touse'
			matrix `rmat'_`v'[`i',3] = r(N)
			count if `v' == 1 & `1' == 1 & `touse'
			matrix `rmat'_`v'[`i',4] = r(N)
		}

		// matrix rownames `rmat' = `varlist2'
		matrix colnames `rmat'_`v' = ActualNeg ActualPos TrueNeg FalsePos
		if "`print'" != "noprint" {
			local form ", noheader"
			if "`format'" != "" {
				local form "`form format'"
			}
			di as result "Results for test variable `v'"
			matrix list `rmat'_`v' `form'
			di `sp'
		}
		if "`matrix'" != "" {
			matrix `matrix' = `rmat'_`v'
		}
		return matrix rmat_`v' = `rmat'_`v'
	}
	return local varname `varlist'

end

