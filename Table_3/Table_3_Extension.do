************************************************************
* EXTENSION for Table 3:
* Δ max benefit (2010-1991) on 1991 state characteristics
* + add initial max benefit (1991) for path dependence
************************************************************

clear all
set more off

use "ui_econ_analysis.dta", clear

* Construct 0/1 dummy consistent with paper:
* neg_ui_rr = 1 if trust fund balance is negative
* (in public data this is typically coded as neg_ui_rr_pct == 100)
gen byte neg_ui_rr = (neg_ui_rr_pct > 0) if !missing(neg_ui_rr_pct)
label var neg_ui_rr "UI trust fund reserve < 0 (dummy)"

* Keep only 1991 and 2010
preserve
keep if inlist(year, 1991, 2010)

* Create 1991 levels and 2010 max benefit
foreach v in unemp_rate ln_realgdp_percap wages_state cov ui_rr neg_ui_rr max_ben {
    gen `v'_1991 = `v' if year==1991
}
gen max_ben_2010 = max_ben if year==2010

* Collapse to one observation per state
collapse (max) unemp_rate_1991 ln_realgdp_percap_1991 wages_state_1991 cov_1991 ///
               ui_rr_1991 neg_ui_rr_1991 max_ben_1991 max_ben_2010, by(stcode)

* Outcome: change in max benefit
gen d_max_ben = max_ben_2010 - max_ben_1991
label var d_max_ben "Change in max benefit (2010-1991)"

* Run extension regressions
cap which esttab
if _rc ssc install estout, replace
eststo clear

* Regression A: 1991 fundamentals only
reg d_max_ben unemp_rate_1991 ln_realgdp_percap_1991 wages_state_1991 cov_1991 ///
    ui_rr_1991 neg_ui_rr_1991, vce(robust)
eststo chgA

* Regression B: add initial max benefit (1991) -> path dependence
reg d_max_ben max_ben_1991 unemp_rate_1991 ln_realgdp_percap_1991 wages_state_1991 ///
    cov_1991 ui_rr_1991 neg_ui_rr_1991, vce(robust)
eststo chgB

* Output (RTF)
esttab chgA chgB using "Table_3/Table3_extension_pathdependence.rtf", replace ///
    b(3) se(3) ///
    mtitle("ΔMaxBen on 1991 levels" "+ add MaxBen(1991)") ///
    keep(max_ben_1991 unemp_rate_1991 ln_realgdp_percap_1991 wages_state_1991 cov_1991 ui_rr_1991 neg_ui_rr_1991) ///
    order(max_ben_1991 unemp_rate_1991 ln_realgdp_percap_1991 wages_state_1991 cov_1991 ui_rr_1991 neg_ui_rr_1991) ///
    stats(N r2, fmt(0 3) labels("States" "R-squared")) ///
    addnotes("Cross-sectional regression: 51 states (one obs per state).", ///
             "Dependent variable: max benefit change between 1991 and 2010.", ///
             "Robust standard errors in parentheses.")

restore
