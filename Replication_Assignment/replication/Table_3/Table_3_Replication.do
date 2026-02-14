*********************************************************
* UI as a Housing Market Stabilizer (Hsu, Matsa, Melzer)
* Replicate Table 3
* Originally from ui_econ_analysis.do
*********************************************************

// #delimit ;

capture do profile.do
cap log close
cap program drop _all
clear all
set more 1
set matsize 800

cd "/Users/miranaaazzz/Desktop/Replication_UI as a Housing Market Stabilizer"
log using "Table_3/Table_3_replication.log", replace

/********************************************************
*********************************************************
*********************************************************

	Unemployment Insurance as a Housing Market Stabilizer

	FILENAME: UI_econ_analysis.do

	Analyses of economic determinants of UI generosity
	and impact of UI generosity on benefit payments.
	
	1991 - 2010
	
	Results presented in Tables 1, 2 and 3 of the paper.
	
	VARIABLES
	
	stcode: state FIPS code
	year: year
	wba_max_thousands: maximum weekly UI benefit ($ thousands)
	duration_max: maximum number of weeks for which regular UI benefits are paid 
	eb_euc_weeks: maximum number of weeks for which EB and EUC benefits are paid 
	max_ben: wba_max_thousands * duration_max
	max_ben_real: max_ben deflated to 2011 dollars
	max_ben_wages: max_ben / (wages_state / 2)  (fraction of average semi-annual wages)
	ln_max_ben: ln(max_ben)
	max_ben_eb_euc: wba_max_thousands * eb_euc_weeks
	unemp_rate: unemployment rate
	ln_realgdp_percap: log of real GDP per capita
	wages_state: average wages
	cov: union coverage rate
	ui_rr: UI trust fund reserve ratio
	neg_ui_rr_pct: indicator for a negative UI trust fund balance * 100
	log_ui_benefits_reg: aggregate regular UI benefit payments 
	log_inc_maint: aggregate non-UI transfer payments 
	log_pub_med: aggregate state health insurance payments
		
*********************************************************
*********************************************************
********************************************************/

use "ui_econ_analysis.dta", clear

*** NOTE: We have dropped non-public information on home price growth used
*** in our analysis. Specifically, we exclude the variable "hpi_growth,"
*** referenced below, which measures the year-over-year growth rate of
*** the Case-Shiller state-level home price index. Our data contract prevents
*** us from publishing the values of the index and the home price growth. Users
*** who obtain the state-level Case-Shiller Indexes from CoreLogic
*** (http://www.corelogic.com/products/corelogic-case-shiller.aspx)
*** can merge those data (by state and year) with ui_econ_analysis.dta and
*** run the code below. 



// Table 3 - Regressions of UI generosity on economic variables with state and year fixed effects(delete hpi_growth)

areg max_ben unemp_rate year_dum*, a(stcode) cl(stcode)
*outreg2 using t3_fe, excel alpha (0.01, 0.05, 0.10) bdec(3) rdec(2) sdec(3) drop (year_dum*) replace

foreach var of var ln_realgdp_percap wages_state cov ui_rr neg_ui_rr {
areg max_ben `var' year_dum*, a(stcode) cl(stcode)
  *outreg2 using t3_fe, excel alpha (0.01, 0.05, 0.10) bdec(3) rdec(2) sdec(3) drop (year_dum*) append
}
areg max_ben unemp_rate ln_realgdp_percap wages_state cov ui_rr neg_ui_rr year_dum*, a(stcode) cl(stcode)
  *outreg2 using t3_fe, excel alpha (0.01, 0.05, 0.10) bdec(3) rdec(2) sdec(3) drop (year_dum*) append

log close  
  

  
*********************************************************
* Table 3 Replication: Max Benefit on econ conditions
* Keep column (3) as blank (House price growth unavailable)
* Make "reserve < 0?" consistent with paper (0/1 dummy)
*********************************************************

* Load the dataset right here (so variables exist)
use "ui_econ_analysis.dta", clear

* Build 0/1 dummy consistent with paper
gen byte neg_ui_rr = (neg_ui_rr_pct == 100)

* quick check
tab neg_ui_rr neg_ui_rr_pct, missing

cap which esttab
if _rc ssc install estout, replace
eststo clear

* (1) Unemployment rate
quietly areg max_ben unemp_rate year_dum*, absorb(stcode) vce(cluster stcode)
eststo c1

* (2) log real GDP per capita
quietly areg max_ben ln_realgdp_percap year_dum*, absorb(stcode) vce(cluster stcode)
eststo c2

* (3): BLANK placeholder (House price growth is proprietary)
quietly areg max_ben year_dum*, absorb(stcode) vce(cluster stcode)
eststo c3

* (4) Average wage
quietly areg max_ben wages_state year_dum*, absorb(stcode) vce(cluster stcode)
eststo c4

* (5) Union coverage
quietly areg max_ben cov year_dum*, absorb(stcode) vce(cluster stcode)
eststo c5

* (6) UI trust fund reserves (% of covered wages)
quietly areg max_ben ui_rr year_dum*, absorb(stcode) vce(cluster stcode)
eststo c6

* (7) UI trust fund reserve < 0 ?
quietly areg max_ben neg_ui_rr year_dum*, absorb(stcode) vce(cluster stcode)
eststo c7

* (8) All controls together
quietly areg max_ben unemp_rate ln_realgdp_percap wages_state cov ui_rr neg_ui_rr ///
    year_dum*, absorb(stcode) vce(cluster stcode)
eststo c8

* Output(RTF)
esttab c1 c2 c3 c4 c5 c6 c7 c8 using "Table_3/Table3_replication.rtf", replace ///
    b(3) se(3) ///
    keep(unemp_rate ln_realgdp_percap wages_state cov ui_rr neg_ui_rr) ///
    order(unemp_rate ln_realgdp_percap wages_state cov ui_rr neg_ui_rr) ///
    stats(N r2, fmt(0 2) labels("Observations" "R-squared")) ///
    addnotes("State and year fixed effects: Yes." ///
             "Standard errors clustered at the state level." ///
             "Column (3) intentionally left blank: house price growth (Case-Shiller/CoreLogic) is proprietary and excluded from public replication data.")

			 
			 