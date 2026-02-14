// #delimit ;

do profile.do
cap log close
cap program drop _all
cap clear all
set more 1
set mem 300m
set matsize 800

// Set working directory

cd "UI and Credit/AER Data and Code"

log using ui_econ_analysis.log, replace

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


// Table 1, summary statistics - UI generosity and state economic variables

tabstat max_ben wba_max_thousands duration_max max_ben_real ln_max_ben max_ben_wages ui_rr neg_ui_rr_pct max_ben_eb_euc eb_euc_weeks, stat(n mean med sd) col(stat)
tabstat unemp_rate ln_realgdp_percap hpi_growth wages_state cov, stat(n mean med sd) col(stat)


// Table 2 - Regressions of log benefit payments (UI, non-UI transfers and state health insurance) on UI generosity and control variables (including state and year fixed effects)

areg log_ui_benefits_reg max_ben year_dum*, a(stcode) cl(stcode)
  *outreg2 using t2_pmt, excel alpha (0.01, 0.05, 0.10) bdec(3) rdec(2) sdec(3) drop (year_dum*) replace

areg log_ui_benefits_reg ln_max_ben year_dum*, a(stcode) cl(stcode)
  *outreg2 using t2_pmt, excel alpha (0.01, 0.05, 0.10) bdec(3) rdec(2) sdec(3) drop (year_dum*) append

areg log_ui_benefits_reg max_ben unemp_rate ln_realgdp_percap hpi_growth wages_state cov year_dum*, a(stcode) cl(stcode)
  *outreg2 using t2_pmt, excel alpha (0.01, 0.05, 0.10) bdec(3) rdec(2) sdec(3) drop (year_dum*) append

areg log_ui_benefits_reg ln_max_ben unemp_rate ln_realgdp_percap hpi_growth wages_state cov year_dum*, a(stcode) cl(stcode)
  *outreg2 using t2_pmt, excel alpha (0.01, 0.05, 0.10) bdec(3) rdec(2) sdec(3) drop (year_dum*) append

areg log_inc_maint ln_max_ben unemp_rate ln_realgdp_percap hpi_growth wages_state cov year_dum*, a(stcode) cl(stcode)
  *outreg2 using t2_pmt, excel alpha (0.01, 0.05, 0.10) bdec(3) rdec(2) sdec(3) drop (year_dum*) append

areg log_pub_med ln_max_ben unemp_rate ln_realgdp_percap hpi_growth wages_state cov year_dum*, a(stcode) cl(stcode)
  *outreg2 using t2_pmt, excel alpha (0.01, 0.05, 0.10) bdec(3) rdec(2) sdec(3) drop (year_dum*) append


// Table 3 - Regressions of UI generosity on economic variables with state and year fixed effects

areg max_ben unemp_rate year_dum*, a(stcode) cl(stcode)
*outreg2 using t3_fe, excel alpha (0.01, 0.05, 0.10) bdec(3) rdec(2) sdec(3) drop (year_dum*) replace

foreach var of var ln_realgdp_percap hpi_growth wages_state cov ui_rr neg_ui_rr {
areg max_ben `var' year_dum*, a(stcode) cl(stcode)
  *outreg2 using t3_fe, excel alpha (0.01, 0.05, 0.10) bdec(3) rdec(2) sdec(3) drop (year_dum*) append
}
areg max_ben unemp_rate ln_realgdp_percap hpi_growth wages_state cov ui_rr neg_ui_rr year_dum*, a(stcode) cl(stcode)
  *outreg2 using t3_fe, excel alpha (0.01, 0.05, 0.10) bdec(3) rdec(2) sdec(3) drop (year_dum*) append

log close
