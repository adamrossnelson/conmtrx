capture program drop maketest
program maketest
	version 13
	syntax anything(id="argument numlist") [if] [in] [, ROWlabel(string) COLlabel(string) VARiables(integer 999) PROBabilities(integer 999)]

	if "`rowlabel'" == "" {
		local rowlabel = "Predicted"
	}

	if "`collabel'" == "" {
		local collabel = "Actual"
	}	
	
	di "`anything'"
	di "`rowlabel'"
	di "`collabel'"
	di "`variables'"
	di "`probabilities'"
	
	tokenize `anything'
	local tally : word count `anything'
	
	di "`tally'"
	di "`1'"
	di "`2'"
	
	if `tally' == 2 {
		forvalues i = 1/2 {
			capture confirm numeric variable ``i''
			if _rc {
				di "ERROR: Specified variables does not exist or is not binary & numeric."
				exit = 452
			}
		}
		
		tab `1' `2'
		
		if r(r) == 2 & r(c) == 2 {
			sum `1'
			if r(min) == 0 & r(max) == 1 {
				qui distinct `2'
				local dist= r(ndistinct)
				sum `2'
				if r(min) == 0 & r(max) == 1 {
					di "{ul:Specified variables binary. Producing confusion matrix.}"
					tab `1' `2', row matcell(miscmat)
					local trueneg = miscmat[1,1]
					local falseneg = miscmat[1,2]
					local falspos = miscmat[2,1]
					local truepos = miscmat[2,2]
					classtabi `trueneg' `falseneg' `falspos' `truepos', rowlabel(`rowlabel') collabel(`collabel')
					local rout = 2
				}
				else {
					di "ERROR: Second variable not binary. Values must be 0 or 1."
					exit = 452
				}
			}
			else {
				di "ERROR: First variable not binary. Values must be 0 or 1."
				exit = 452
			}
			else {
				di "ERROR: Variables must be coded as 0 or 1."
				exit = 452
			}
		}
	}
	else if `tally' == 4 {
		classtabi `1' `2' `3' `4', rowlabel(`rowlabel') collabel(`collabel')
	}
	else if (`tally' == 3) {
		di "ERROR: Must specify 2 variables or 4 probabilities arguments."
		exit = 197
	}
	else if (`tally' > 4) {
		di "ERROR: Too many arguments."
		exit = 103
	}
	else if (`tally' < 2) {
		di "ERROR: Too few arguments."
		exit = 102
	}
end
