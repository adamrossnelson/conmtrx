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
	[,noPRINT noCOIN PROBs(string asis) FORmat(passthru) MATrix(string)]
	
	local sp char(13) char(10) // Define spacer.

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
	if "`coin'" != "" & "`coin'" != "nocoin" {
		di as error "ERROR: Coin option incorrectly specified."
		errir 198
	}
	// Test that coin and probs not both specified
	if "`coin'" == "nocoin" & "`probs'" != ""{
		di as error "ERROR: Nocoin option may not be combined with probs option."
		error 198
	}

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

	// Build Matricies
	local varlist2 = substr("`varlist'",strpos("`varlist'"," "),strlen("`varlist'") - strpos("`thelist'"," "))
	local varlist3 = "`varlist2'"
	if "`coin'" != "nocoin" {
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
	matrix `rmat' = J(20, `nvar' + `totcoins' - 1,.)
	local i = 1
	foreach v of varlist `varlist3' {
		qui {
			// ObservedNeg
			count if `1' == 0 & `touse'
			matrix `rmat'[1,`i'] = r(N)
			// ObservedPos
			count if `1' == 1 & `touse'
			matrix `rmat'[2,`i'] = r(N)
			// ObservedTot
			matrix `rmat'[3,`i'] = `rmat'[1,`i'] + `rmat'[2,`i']
			// TestedNeg
			count if `v' == 0 & `touse'
			matrix `rmat'[4,`i'] = r(N)
			// TestedPos
			count if `v' == 1 & `touse'
			matrix `rmat'[5,`i'] = r(N)
			// TestedTot
			matrix `rmat'[6,`i'] = `rmat'[4,`i'] + `rmat'[5,`i']
			// TrueNeg
			count if `1' == 0 & `v' == 0 & `touse'
			matrix `rmat'[7,`i'] = r(N)
			// TruePos
			count if `1' == 1 & `v' == 1 & `touse'
			matrix `rmat'[8,`i'] = r(N)
			// FalseNeg
			count if `v' == 0 & `1' == 1 & `touse'
			matrix `rmat'[9,`i'] = r(N)
			// FalsePos
			count if `v' == 1 & `1' == 0 & `touse'
			matrix `rmat'[10,`i'] = r(N)
			// Prevalence
			matrix `rmat'[11,`i'] = `rmat'[2,`i'] / `rmat'[3,`i']
			// Sensitivity aka true positive rate (TPR)
			matrix `rmat'[12,`i'] = `rmat'[8,`i'] / `rmat'[2,`i']
			// Specificity aka true negative rate

			// PosPredVal aka precision

			// NegPredVal 

			// False

			// For reference: https://en.wikipedia.org/wiki/Sensitivity_and_specificity
		}
		local ++i
	}

	matrix colnames `rmat' = `varlist3'
	matrix rownames `rmat' = ObservedNeg ObservedPos ObservedTot TestedNeg TestedPos TestedTot ///
	TrueNeg TruePos FalseNeg FalsePos ///
	Prevalence Sensitivity Specificity PosPredVal NegPredVal ///
	FalsePosRt FalseNegRt CorrectRt IncorrectRt ROCArea
	if "`print'" != "noprint" {
		local form ", noheader"
		if "`format'" != "" {
			local form "`form' `format'"
		}
		matrix list `rmat' `form'
		di "             "
		di "           Prevalence = ObservedPos/ObservedTot   Sensitivity = TruePos/ObservedPos"
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

