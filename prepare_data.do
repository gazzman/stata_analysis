#!/usr/local/stata/stata
clear
set more off

/*************************************************************
Generate daily adjusted returns from Yahoo! Finance prices
*************************************************************/
insheet using `1', comma

// Generate the date
gen date2 = date(date, "YMD")
drop date
ren date2 date
order date

// Calculate the returns
sort ticker date
gen adjreturn = 100*(adjclose[_n]/adjclose[_n-1] - 1) if ticker[_n] == ticker[_n-1]
format date %tdCCYY-NN-DD
format volume %12.0f
format adjreturn %05.4f

save prices.dta, replace

/*************************************************************
Merge the factor data with the return data
*************************************************************/
insheet using `2', comma clear

// Generate the date
gen date2 = string(date, "%10.0f")
gen date3 = date(date2, "YMD")
format date3 %tdCCYY-NN-DD
drop date date2
ren date3 date
order date

save factors.dta, replace
use prices.dta, clear

// Merge the prices with the factors
merge m:1 date using factors.dta

drop if _merge != 3
drop _merge

// Compute adjusted excess returns
gen adjexcret = adjreturn - rf
order date-adjreturn adjexcret
sort ticker date

// Reshape wide for generating date id
reshape wide dividends-adjexcret, i(date) j(ticker) string

// Set 
sort date
gen t = _n


order t date mktrf smb hml rf
tsset t /*

/*************************************************************
Reshape long for storing as panel data
*************************************************************/
reshape long dividends open high low close volume adjclose adjreturn adjexcret, i(date) j(ticker) string
encode(ticker), generate(j)
order t j date ticker
sort j t
xtset j t
*/

/*************************************************************
Keep as wide for storing as time-series vector (useful for SUR)
*************************************************************/
save combined.dta, replace

sum t
local max_t = r(max)
//local ft = `max_t' - 252*3
local ft = `max_t' - 21*2
//sureg (adjexcret* = mktrf) if t > `ft', corr
//sureg adjexcret* = L.adjexcret* mktrf if t > `ft', corr
//mvreg adjexcret* = mktrf if t > `ft', corr
mvreg adjexcret* = mktrf smb hml if t > `ft', corr
