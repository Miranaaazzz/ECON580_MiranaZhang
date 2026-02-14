capture log close
clear all
set mem 400m
set more off

log using "UI and Credit/AER Data and Code/ui_nlsy_analysis.log", replace

/********************************************************
*********************************************************
*********************************************************

	Unemployment Insurance as a Housing Market Stabilizer

	FILENAME: UI_nlsy_analysis.do

	Analysis of home foreclosure and UI extended 
	benefits generosity using NLSY 1979 data from
	2010 and 2012 interviews.
	
	Results presented in Tables 1 and 9 of paper.
	
	HOUSEHOLD-LEVEL VARIABLES:
	
	caseid: individual identifier
	sampweight_: sample weight
	layoff: indicator for whether household reference person had a layoff spell since prior NLSY interview
	delinquency: indicator for mortgage delinquency
	foreclosure: indicator for home foreclosure initiation
	lost_home: indicator for home foreclosure completion
	educ_cat: education category
	neg_equity_lag: indicator for whether homeowner had a negative equity position on occupied home as of prior interview. (Coded as zero if missing.)
	ltv_win_lag: homeowner's mortgage loan-to-value ratio on occupied home, winsorized at the 99th percentile, as of the prior interview. (Coded as zero if missing.)
	neg_equity2nd_lag: indicator for whether homeowner had a negative equity position on second home as of prior interview. (Coded as zero if missing or no second property.)
	ltv_win2nd_lag: homeowner's mortgage loan-to-value ratio on second home, winsorized at the 99th percentile, as of the prior interview. (Coded as zero if missing or no second property.)
	net_worth_lag: household net worth as of the prior interview. (Coded as zero if missing.)
	earnings_lag: household annual earnings as of the prior interview. (Coded as zero if missing.)                 
	ltv_win_lag_missing: indicator for whether loan-to-value information was missing as of prior interview.
	neg_equity_lag_missing: indicator for whether loan-to-value information was missing as of prior interview.                 
	net_worth_lag_missing: indicator for whether net worth information was missing as of prior interview.
	earnings_lag_missing: indicator for whether earnings information was missing as of prior interview.                 
	ltv_win2nd_lag_missing: indicator for whether loan-to-value information on second property was missing as of prior interview.                 
	neg_equity2nd_lag_missing: indicator for whether loan-to-value information on second property was missing as of prior interview.
	
	*note: all ltv and neg_equity variables above with "dm" appended are de-meaned relative to regression sample mean.
	
	STATE-LEVEL VARIABLES
	
	st_fips: state FIPS code
	year: year of interview
	st_yr: categorical variable indicating state-year groups
	max_ben_eb_euc_avg_dm: average value of max_ben_eb_euc over two years prior to interview date (de-meaned within sample)
	eb_euc_weeks_avg_dm: average value of eb_euc_weeks over two years prior to interview date (de-meaned within sample)
	tur_avg_dm: average value of total unemployment rate over two years prior to interview date (de-meaned within sample)

	
*********************************************************
*********************************************************
********************************************************/

use "UI and Credit/AER Data and Code/ui_nlsy_analysis.dta", clear

**** The analysis below uses state-level variables that we suppress from ui_nlsy_analysis.dta to avoid disclosing non-public
**** state identifiers. We obtained state identifiers for NLSY respondents by applying to the BLS. Other researchers
**** that obtain state identifiers can merge the state variables (ui_nlsy_state_variables.dta) to ui_nlys_analysis.dta as 
**** indicated below.

sort st_fips year
merge m:1 st_fips year using "UI and Credit/AER Data and Code/ui_nlsy_state_variables.dta"
drop _merge

*****

global ind_controls "i.educ_cat earnings_lag net_worth_lag ltv_win_lag ltv_win2nd_lag c.neg_equity_lag_dm##i.layoff c.neg_equity2nd_lag_dm##i.layoff c.ltv_win_lag_dm##i.layoff c.ltv_win2nd_lag_dm##i.layoff" 
global ind_controls_missing "net_worth_lag_missing earnings_lag_missing ltv_win_lag_missing ltv_win2nd_lag_missing c.neg_equity_lag_missing_dm##i.layoff c.neg_equity2nd_lag_missing_dm##i.layoff c.ltv_win_lag_missing_dm##i.layoff c.ltv_win2nd_lag_missing_dm##i.layoff"

global ind_controls2 "i.educ_cat earnings_lag net_worth_lag ltv_win_lag ltv_win2nd_lag c.neg_equity_lag_dm2##i.layoff c.neg_equity2nd_lag_dm2##i.layoff c.ltv_win_lag_dm2##i.layoff c.ltv_win2nd_lag_dm2##i.layoff" 
global ind_controls_missing2 "net_worth_lag_missing earnings_lag_missing ltv_win_lag_missing ltv_win2nd_lag_missing c.neg_equity_lag_missing_dm2##i.layoff c.neg_equity2nd_lag_missing_dm2##i.layoff c.ltv_win_lag_missing_dm2##i.layoff c.ltv_win2nd_lag_missing_dm2##i.layoff"

***Table 1, Panel C - Summary statistics

quietly areg foreclosure c.max_ben_eb_euc_avg_dm##i.layoff i.year $ind_controls $ind_controls_missing [pw=sampweight_], a(st_yr) cl(st_fips)

sum foreclosure lost_home layoff [aw=sampweight_] if e(sample), detail

foreach i of varlist earnings_lag net_worth_lag ltv_win_lag ltv_win2nd_lag neg_equity_lag neg_equity2nd_lag {
sum `i' [aw=sampweight_] if e(sample) & `i'_missing == 0, detail
}

tab educ_cat [aw = sampweight_] if e(sample)

***Table 9 - Regressions of foreclosure initiation ("foreclosure") and completion ("lost_home") on layoff indicator, UI generosity and control variables

*** Foreclosure

areg foreclosure c.max_ben_eb_euc_avg_dm##i.layoff i.year $ind_controls $ind_controls_missing [pw=sampweight_], a(st_yr) cl(st_fips)
*outreg2 using "UI and Credit/Tables/table_NLSY_foreclosure", alpha (0.01, 0.05, 0.10) bdec(2) rdec(3) sdec(2) nocons append
areg foreclosure c.max_ben_eb_euc_avg_dm##i.layoff i.layoff##c.tur_avg_dm##c.tur_avg_dm##c.tur_avg_dm i.year $ind_controls $ind_controls_missing [pw=sampweight_], a(st_yr) cl(st_fips)
*outreg2 using "UI and Credit/Tables/table_NLSY_foreclosure", alpha (0.01, 0.05, 0.10) bdec(2) rdec(3) sdec(2) nocons append 
areg foreclosure c.eb_euc_weeks_avg_dm##i.layoff i.layoff##c.tur_avg_dm##c.tur_avg_dm##c.tur_avg_dm i.year $ind_controls $ind_controls_missing [pw=sampweight_], a(st_yr) cl(st_fips)
*outreg2 using "UI and Credit/Tables/table_NLSY_foreclosure", alpha (0.01, 0.05, 0.10) bdec(2) rdec(3) sdec(2) nocons append 

*** Lost Home

areg lost_home c.max_ben_eb_euc_avg_dm##i.layoff i.year $ind_controls $ind_controls_missing [pw=sampweight_], a(st_yr) cl(st_fips)
*outreg2 using "UI and Credit/Tables/table_NLSY_lost_home", alpha (0.01, 0.05, 0.10) bdec(2) rdec(3) sdec(2) nocons append
areg lost_home c.max_ben_eb_euc_avg_dm##i.layoff i.layoff##c.tur_avg_dm##c.tur_avg_dm##c.tur_avg_dm i.year $ind_controls $ind_controls_missing [pw=sampweight_], a(st_yr) cl(st_fips)
*outreg2 using "UI and Credit/Tables/table_NLSY_lost_home", alpha (0.01, 0.05, 0.10) bdec(2) rdec(3) sdec(2) nocons append 
areg lost_home c.eb_euc_weeks_avg_dm##i.layoff i.layoff##c.tur_avg_dm##c.tur_avg_dm##c.tur_avg_dm i.year $ind_controls $ind_controls_missing [pw=sampweight_], a(st_yr) cl(st_fips)
*outreg2 using "UI and Credit/Tables/table_NLSY_lost_home", alpha (0.01, 0.05, 0.10) bdec(2) rdec(3) sdec(2) nocons append 

log close
