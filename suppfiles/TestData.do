set more off
clear all
set obs 162

set seed 1000

gen observed = round(runiform(.49999,.500001))
gen srtr = runiform(1,100)
sort srtr

replace srtr = runiform(1,10)
sort srtr

gen test1 = observed
replace test1 = 1 if _n > 55

replace srtr = runiform(10,200)
sort srtr

gen test2 = 0
replace test2 = 1 if _n > 10

replace srtr = runiform(10,200)
sort srtr

gen test3 = observed
replace test3 = 1 if _n > 88
replace test3 = 0 if _n < 22

gen test4 = observed

discard

conrpt observed test*, probs(10 33 50 66 90) nolegend perfect format(%9.4g)
conrpt observed test*, probs(10 33 50 66 90) perfect format(%9.4g)

conmtrx test2 observed


