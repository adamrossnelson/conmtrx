*! X.X.X Adam Ross Nelson 09oct2017 // Updated to reference adhoc classtabi3
*! X.X.X Adam Ross Nelson 02oct2017 // Original version
*! Original author : Adam Ross Nelson
*! Maintained at   : https://raw.githubusercontent.com/adamrossnelson/conmtrx.ado/
*! Dependency      : classtabi & modified version (classtabi3)

capture program drop conmtrx
program conmtrx
	syntax anything(id="argument numlist") [if] [in] [, ROWlabel(string) COLlabel(string) VARlab(string)]

	capture which classtabi
	if _rc {
		ssc install classtabi
	}

	if "`varlab'" != "" & ("`rowlabel'" != "" | "`collabel'" != "") {
		di in smcl as error "ERROR: Option conflict {ul:row}label or {ul:col}label may not be specified with -{ul:var}lab-option."
		exit = 452
	}

	if "`varlab'" == "" {
		if "`rowlabel'" == "" {
			local rowlabel = "Reference Classification"
		}

		if "`collabel'" == "" {
			local collabel = "Classification Test Result"
		}	
	}
	
	local 2 = subinstr("`2'",",","",.)

	if "`varlab'" == "yes" {
		local rowlabel: variable label `2'
		local collabel: variable label `1'
	}
	else if "`varlab'" != "" {
		di in smcl as error "ERROR: Option -{ul:var}lab- incorrecly specified. Case-sensitive. Option"
		di in smcl as error "var(yes) or varlab(yes) to display variable labels in output."
		exit = 452
	}


	tokenize `anything'
 	local tally : word count `anything'

	if `tally' == 2 {
		forvalues i = 1/2 {
			capture confirm numeric variable ``i''
			if _rc {
				di in smcl as error "ERROR: One or both specified variables do not exist or not binary & numeric."
				exit = 452
			}
		}
		
		qui tab `1' `2'
		
		if r(r) == 2 & r(c) == 2 {
			qui sum `1'
			if r(min) == 0 & r(max) == 1 {
				qui distinct `2'
				local dist= r(ndistinct)
				qui sum `2'
				if r(min) == 0 & r(max) == 1 {
					di "{green:{ul:Specified variables binary. Producing confusion matrix.}}"
					qui tab `1' `2', row matcell(miscmat)
					local trueneg = miscmat[1,1]
					local falseneg = miscmat[1,2]
					local falspos = miscmat[2,1]
					local truepos = miscmat[2,2]
					classtabi3 `trueneg' `falspos' `falseneg' `truepos', rowlabel(`rowlabel') collabel(`collabel')
					local rout = 2
				}
				else {
					di in smcl as error "ERROR: Second variable not binary. Values must be 0 or 1."
					exit = 452
				}
			}
			else {
				di in smcl as error "ERROR: First variable not binary. Values must be 0 or 1."
				exit = 452
			}
			else {
				di in smcl as error "ERROR: Variables must be coded as 0 or 1."
				exit = 452
			}
		}
	}
	else if `tally' == 4 {
		forvalues i = 1/4 {
			capture confirm integer number ``i''
			if _rc {
				di in smcl as error "ERROR: `tally' arguments specified. All must be integers."
				exit = 452
			}
		}
		classtabi3 `1' `2' `3' `4', rowlabel(`rowlabel') collabel(`collabel')
	}
	else if (`tally' == 3) {
		di in smcl as error "ERROR: `tally' arguments specified. Must specify 2 variables or 4 probabilities arguments."
		exit = 197
	}
	else if (`tally' > 4) {
		di in smcl as error "ERROR: `tally' arguments specified. Too many arguments."
		exit = 103
	}
	else if (`tally' < 2) {
		di in smcl as error "ERROR: `tally' arguments specified. Too few arguments."
		exit = 102
	}
	di "{it: - conmtrx - }Command was a success."
end
