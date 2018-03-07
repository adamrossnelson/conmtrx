*! NEW DEV . . .

capture program drop conrpt
program define conrpt, rclass byable(recall)
	// Version control
	version 15
	preserve

	// Syntax statement limits first argument to variable name which must be
	// binary. Subsequent arguments varlist of one or more vars which also must
	// be binary. Includes support for if and in qualifiers.
	syntax varlist(min=2 numeric) [if] [in] ///
	[,NOPrint FORmat(passthru) MATrix(string) ///
	COIn(string) PROBs(string asis)]
	
	local sp char(13) char(10) // Define spacer.

	// Tag subsample with temp var touse & test if empty.
	marksample touse
	quietly count if `touse'
	if `r(N)' == 0 {
		di as error "ERROR: No observations after if or in qualifier."
		error 2000
	}
	// Test that sample large enough for coins.
	if `r(N)' < 99 {
		di as result "WARNING: Coin option less reliable when sample size is low."
		di as result "         Current sample size is `r(N)'."
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

	// Test that coin option correction specified
	if "`coin'" != "" & "`coin'" != "off" {
		di as error "ERROR: Coin option incorrectly specified."
	}

	// Build Matricies
	local varlist2 = substr("`varlist'",strpos("`varlist'"," "),strlen("`varlist'") - strpos("`thelist'"," "))
	local varlist3 = "`varlist2'"
	if "`coin'" != "off" {
		set seed 1000
		gen _srtr = runiform(1,100)
		local totcoins = 0
		if "`probs'" == "" {
			local probs 25 50 75
		}
		foreach prob in `probs' {
			qui {
				gen p`prob'coin = 0
				replace p`prob'coin = 1 if _srtr < `prob'
				local varlist3 = "`varlist3' p`prob'coin"
				local ++totcoins
			}
		}
	}
	tempname rmat
	matrix `rmat' = J(18, `nvar' + `totcoins' - 1,.)
	local i = 1
	foreach v of varlist `varlist3' {
		qui {
			count if `1' == 0 & `touse'
			matrix `rmat'[1,`i'] = r(N)
			count if `1' == 1 & `touse'
			matrix `rmat'[2,`i'] = r(N)
			count if `v' == 0 & `1' == 0 & `touse'
			matrix `rmat'[3,`i'] = r(N)
			count if `v' == 1 & `1' == 0 & `touse'
			matrix `rmat'[4,`i'] = r(N)
			count if `v' == 0 & `touse'
			matrix `rmat'[5,`i'] = r(N)
			count if `v' == 1 & `touse'
			matrix `rmat'[6,`i'] = r(N)
			count if `v' == 0 & `1' == 1 & `touse'
			matrix `rmat'[7,`i'] = r(N)
			count if `v' == 1 & `1' == 1 & `touse'
			matrix `rmat'[8,`i'] = r(N)
		}
		local ++i
	}

	matrix colnames `rmat' = `varlist3'
	matrix rownames `rmat' = ObservedNeg ObservedPos TestedNeg TestedPos ///
	TrueNeg TruePos FalseNeg FalsePos ///
	Prevalence Sensitivity Specificity PosPredVal NegPredVal ///
	FalsePosRt FalseNegRt CorrectRt IncorrectRt ROCArea
	if "`print'" != "noprint" {
		local form ", noheader"
		if "`format'" != "" {
			local form "`form format'"
		}
		matrix list `rmat' `form'
		di `sp'
	}
	if "`matrix'" != "" {
		matrix `matrix' = `rmat'
	}
	return matrix rmat = `rmat'              // Return matrix
	
	return local varnames `varlist'          // Return full varlist
	return local testnames `varlist2'        // Return test variables
	return local obsvar `1'                  // Return observed variable

	restore
end

