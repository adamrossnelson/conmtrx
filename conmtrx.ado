// Program that simplifies syntax of the classtabi package.
// Instead of classtabi #a #b #c #d [, rowlabel(string) collabel(string)]
// Simplified syntax is conmtrx rowvar colvar.
//
// Origin date     : October 2, 2017
// Original author : Adam Ross Nelson
// Maintained at   : https://raw.githubusercontent.com/adamrossnelson/conmtrx.ado/

program conmtrx
	capture which distinct
	if _rc {
		ssc install distinct
	}
	capture which classtabi
	if _rc {
		ssc install classtabi
	}

	local rout = 0
	while `rout' < 1 & "`1'" != "" & "`2'" != "" {
		qui distinct `1'
		local dist = r(ndistinct)
		qui sum `1'
		if r(min) == 0 & r(max) == 1 & `dist' == 2 {
			qui distinct `2'
			local dist= r(ndistinct)
			qui sum `2'
			if r(min) == 0 & r(max) == 1 & `dist' == 2 {
				di "Specified variables binary. Producing confusion matrix."
				tab `1' `2', row matcell(miscmat)
				local trueneg = miscmat[1,1]
				local falseneg = miscmat[1,2]
				local falspos = miscmat[2,1]
				local truepos = miscmat[2,2]
				classtabi `trueneg' `falseneg' `falspos' `truepos', rowlabel(Predicted) collabel(Actual)
				local rout = 2
			}
			else {
				di "Second variable not binary. Values must be 0 or 1."
				local rout = 1
			}
		}
		else {
			di "First variable not binary. Values must be 0 or 1."
			local rout = 1
		}
	}
	if `rout' < 2 {	
		di "Appropriate variables not specified."
	}
	else {
		di " - conmtrx - Command was a succss."
	}
end
