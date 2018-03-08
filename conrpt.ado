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
	[,noPRINT noCOIN noLEGEND perfect PROBs(string asis) FORmat(passthru) MATrix(string)]
	
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
	if "`perfect'" == "perfect" {
		qui {
			gen perfect = `1' if `touse'
			local varlist3 = "perfect `varlist3'"
			local nvar = `nvar' + 1
		}
	}
	tempname rmat
	matrix `rmat' = J(22, `nvar' + `totcoins' - 1,.)
	local i = 1
	foreach v of varlist `varlist3' {
		qui {
			// ObservedPos   (number of) positive samples (P)
			count if `1' == 1 & `touse'
			matrix `rmat'[1,`i'] = r(N)
			// ObservedNeg   (number of) negative samples (N)
			count if `1' == 0 & `touse'
			matrix `rmat'[2,`i'] = r(N)
			// ObservedTot
			matrix `rmat'[3,`i'] = `rmat'[1,`i'] + `rmat'[2,`i']

			// TestedPos
			count if `v' == 1 & `touse'
			matrix `rmat'[4,`i'] = r(N)
			// TestedNeg
			count if `v' == 0 & `touse'
			matrix `rmat'[5,`i'] = r(N)
			// TestedTot
			matrix `rmat'[6,`i'] = `rmat'[4,`i'] + `rmat'[5,`i']

			// TruePos        // (TP) eqv. with hit
			count if `v' == 1 & `1' == 1 & `touse'
			matrix `rmat'[7,`i'] = r(N)
			// TrueNeg        // (TN) eqv. with correct rejection
			count if `v' == 0 & `1' == 0 & `touse'
			matrix `rmat'[8,`i'] = r(N)
			// FalsePos       // (FP) eqv. with false alarm, Type I error
			count if `v' == 1 & `1' == 0 & `touse'
			matrix `rmat'[9,`i'] = r(N)
			// FalseNeg      // (FN) eqv. with miss, Type II error
			count if `v' == 0 & `1' == 1 & `touse'
			matrix `rmat'[10,`i'] = r(N)

			// Prevalence                                       // (ObservedPos/ObservedTot)
			matrix `rmat'[11,`i'] = (`rmat'[1,`i']  / `rmat'[3,`i'])                    * 100
			// Sensitivity aka true positive rate (TPR)         // (TruePos/ObservedPos)
			matrix `rmat'[12,`i'] = (`rmat'[7,`i']  / `rmat'[1,`i'])                    * 100
			// Specificity aka true negative rate (TNR)         // (TrueNeg/ObservedNeg)
			matrix `rmat'[13,`i'] = (`rmat'[8,`i']  / `rmat'[2,`i'])                    * 100

			// PosPredVal aka precision                         // (TruePos/(TruePos+FalsePos))
			matrix `rmat'[14,`i'] = (`rmat'[7,`i']  / (`rmat'[7,`i'] + `rmat'[9,`i']))  * 100
			// NegPredVal aka ...                               // (TrueNeg/(TrueNeg+FalseNeg))
			matrix `rmat'[15,`i'] = (`rmat'[8,`i']  / (`rmat'[8,`i'] + `rmat'[10,`i'])) * 100
			// FalsePosRt aka Inverse Specificity or fall-out   // (FalsePos/ObservedNeg)
			matrix `rmat'[16,`i'] = (`rmat'[9,`i']  / `rmat'[2,`i'])                    * 100
			// FalseNegRt aka Inverse Sensitivity               // (FalseNeg/(FalseNeg+TruePos))
			matrix `rmat'[17,`i'] = (`rmat'[10,`i'] / (`rmat'[10,`i'] + `rmat'[7,`i'])) * 100

			// CorrectRt aka Accuracy                           // (TruePos+TrueNeg)/TestedTot
			matrix `rmat'[18,`i'] = ((`rmat'[7,`i'] + `rmat'[8,`i'])  / `rmat'[6,`i'])  * 100
			// IncorrectRt                                      // (FalsePos+FalseNeg)/TestedTot
			matrix `rmat'[19,`i'] = ((`rmat'[9,`i'] + `rmat'[10,`i']) / `rmat'[6,`i'])  * 100
			
			// ROCArea
			roctab `1' `v'
			return local rocarea r(area)
			matrix `rmat'[20,`i'] = r(area)
			
			// F1 Score aka harmonic mean of precision and sensitivity
			// 2TruePos / (2TruePos + FalsePos + FalseNeg)
			matrix `rmat'[21,`i'] = (2 * `rmat'[7,`i']) / ((2 * `rmat'[7,`i']) + (`rmat'[9,`i'] + `rmat'[10,`i']))
			// Matthews correlation coefficient (MattCorCoef)
			matrix `rmat'[22,`i'] = ///
			((`rmat'[7,`i'] * `rmat'[8,`i']) - (`rmat'[9,`i'] * `rmat'[10,`i'])) / /// (TruePos * TrueNeg) - (FalsePos * FalseNeg)
			sqrt((`rmat'[7,`i'] + `rmat'[9,`i'])  * /// (TruePos + FalsePos)
			     (`rmat'[7,`i'] + `rmat'[10,`i']) * /// (TruePos + FalseNeg)
				 (`rmat'[8,`i'] + `rmat'[9,`i'])  * /// (TrueNeg + FalsePos)
				 (`rmat'[8,`i'] + `rmat'[10,`i']))   // (TrueNeg + FalseNeg)   

			// For reference: https://en.wikipedia.org/wiki/Sensitivity_and_specificity
		}
		local ++i
	}

	matrix colnames `rmat' = `varlist3'
	matrix rownames `rmat' = ObservedPos ObservedNeg ObservedTot TestedPos TestedNeg TestedTot ///
	TruePos TrueNeg FalsePos FalseNeg ///
	Prevalence Sensitivity Specificity PosPredVal NegPredVal ///
	FalsePosRt FalseNegRt CorrectRt IncorrectRt ROCArea F1Score MattCorCoef
	if "`print'" != "noprint" {
		local form ", noheader"
		if "`format'" != "" {
			local form "`form' `format'"
		}
		matrix list `rmat' `form'

		if "`legend'" != "nolegend" {
			di ""
			di "   {ul:Legend of Keywords, Terminology, & Calculations}"
			di ""
			di "   Prevalence  = ObservedPos/ObservedTot"
			di "   Specificity = TrueNeg/ObservedNeg           Sensitivity = TruePos/ObservedPos"
			di "   PosPredVal  = TruePos/(TruePos+FalsePos)    NegPredVal  = TrueNeg/(TrueNeg+FalseNeg)"
			di "   FalsePosRt  = FalsePos/ObservedNeg          FalseNegRt  = (FalseNeg/(FalseNeg+TruePos))"
			di "   CorrectRt   = (TruePos+TrueNeg)/TestedTot   IncorrectRt = (FalsePos+FalseNeg)/TestedTot"
			di ""
			di "   FalsePos    = Type I Error                  FalseNeg    = Type II Error"
			di "   FalsePosRt  = Inverse Specificity           FalseNegRt  = Inverse Sensitivity"
			di ""
		}

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

