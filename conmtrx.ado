*! X.X.X Adam Ross Nelson 09oct2017 // Updated to reference classtabi3
*! X.X.X Adam Ross Nelson 02oct2017 // Original version
*! Original author : Adam Ross Nelson
*! Maintained at   : https://github.com/adamrossnelson/conmtrx/
*! Dependency      : classtabi & modified version (classtabi3)

capture program drop conmtrx
program conmtrx
	version 14.0
	syntax anything(id="argument numlist") [if] [in] [, ROWlabel(string) COLlabel(string) VARlab(string)]

	capture which classtabi3
	if _rc {
		di in smcl as error "ERROR: conmtrx requires classtabi3. Action required:
		di in smcl as error "     ssc install classtabi3"
		// ssc install classtabi
		exit = 452
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
	
	// Remove comma, if there is one.
	local 2 = subinstr("`2'",",","",.)

	if lower("`varlab'") == "yes" {
		local rowlabel: variable label `2'
		local collabel: variable label `1'
	}
	else if "`varlab'" != "" {
		di in smcl as error "ERROR: Option -{ul:var}lab- incorrecly specified. Option"
		di in smcl as error "var(yes) or varlab(yes) to display variable labels in output."
		exit = 452
	}

	tokenize `anything'
 	local tally : word count `anything'

	if `tally' == 2 {
		forvalues i = 1/2 {
			capture confirm numeric variable ``i''
			if _rc {
				di in smcl as error "ERROR: One or both specified variables do not exist or not numeric."
				exit = 452
			}
		}
		qui tab `1' `2'
		if r(r) == 2 & r(c) == 2 {
			capture assert `1' == 1 | `1' == 0
			if _rc {
				di in smcl as error "ERROR: First variable not binary. Values must be 0 or 1."
				exit = 452
			}
			capture assert `2' == 1 | `2' == 0	
			if _rc {
				di in smcl as error "ERROR: Second variable not binary. Values must be 0 or 1."
				exit = 452
			}
			di "{green:{ul:Specified variables binary. Producing confusion matrix.}}"
			qui tab `1' `2', row matcell(miscmat)
			local trueneg = miscmat[1,1]
			local falseneg = miscmat[1,2]
			local falspos = miscmat[2,1]
			local truepos = miscmat[2,2]
			classtabi3 `trueneg' `falspos' `falseneg' `truepos', rowlabel(`rowlabel') collabel(`collabel')
		}
		else {
			di in smcl as error "ERROR: 2 x 2 matrix failed. Variables must be coded as 0 or 1."
			exit = 452
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
		di in smcl as error "ERROR: `tally' arguments specified. Must specify 2 variables or 4 integers as arguments."
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
