do profile.do

clear all
capture log close
set more off
set mem 700m

log using "UI and Credit\log_files\ui_hpi_analysis.log", replace


/********************************************************
*********************************************************
*********************************************************

	Unemployment Insurance as a Housing Market Stabilizer

	FILENAME: UI_hpi_analysis.do

	Analysis of changes county home prices and
	unemployment rates, with sample splits (or
	interactions) by generosity of extended unemployment
	insurance benefits.
	
	2008 - 2013

	Results presented in Table 11 of the paper.
	
	VARIABLES
	
	stcode: state FIPS code
	year: year
	d_log_zillow_hpi: year-over-year change in log of county median home price (Zillow) 
	d_cnty_unemp_rate: year-over-year change in county unemployment rate (BLS)
	max_ben_eb_euc_p75_ind: indicator variable for whether state is in upper quartile of extended UI benefit generosity 
	max_ben_eb_euc_p25_ind: indicator variable for whether state is in bottom quartile of extended UI benefit generosity
	max_ben_eb_euc_dm_post07: maximum dollars of EB and EUC available for full-length unemployment spell in state (de-meaned within regression sample)

*********************************************************
*********************************************************
********************************************************/

use "UI and Credit/AER Data and Code/ui_hpi_analysis.dta", clear

***Table 11

reg d_log_zillow_hpi d_cnty_unemp_rate, cl(stcode)
*outreg2 using "UI and Credit/Tables/table_HPI", alpha (0.01, 0.05, 0.10) bdec(2) rdec(3) sdec(2) nocons append 
reg d_log_zillow_hpi d_cnty_unemp_rate if max_ben_eb_euc_p75_ind == 0, cl(stcode)
*outreg2 using "UI and Credit/Tables/table_HPI", alpha (0.01, 0.05, 0.10) bdec(2) rdec(3) sdec(2) nocons append 
reg d_log_zillow_hpi d_cnty_unemp_rate if max_ben_eb_euc_p25_ind == 1, cl(stcode)
*outreg2 using "UI and Credit/Tables/table_HPI", alpha (0.01, 0.05, 0.10) bdec(2) rdec(3) sdec(2) nocons append 
reg d_log_zillow_hpi c.d_cnty_unemp_rate##c.max_ben_eb_euc_dm_post07, cl(stcode)
*outreg2 using "UI and Credit/Tables/table_HPI", alpha (0.01, 0.05, 0.10) bdec(2) rdec(3) sdec(2) nocons append 

log close

