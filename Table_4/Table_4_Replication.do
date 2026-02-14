*********************************************************
* UI as a Housing Market Stabilizer (Hsu, Matsa, Melzer)
* Replicate Table 4
* Originally from ui_sipp_analysis.do
*********************************************************

capture do profile.do
set more off

use "/Users/miranaaazzz/desktop/Replication_UI as a Housing Market Stabilizer/ui_sipp_analysis.dta", clear

cap log close
log using "/Users/miranaaazzz/desktop/Replication_UI as a Housing Market Stabilizer/Table_4/Table_4_replication.log", replace

* State-level macro and labor market controls
* (home price growth excluded due to data restrictions)
global state_controls "unemp_rate ln_realgdp_percap wages_state ui_rr neg_ui_rr union_cov"

* Household-level controls
* Includes earnings, wealth, education, and mortgage risk,
* with loan-to-value ratio and negative equity interacted
* with layoff status
global ind_controls ///
	"i.layoff##c.ltv_win_demean i.layoff##c.neg_equity_demean earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad"

	
	
*** Table 4: Mortgage Delinquency Regressions
eststo clear

* (1) State FE, no interaction
areg delinq_mort max_ben_demean i.layoff year_dum* $state_controls $ind_controls ///
    [pw = weight_ref], a(stcode) cl(stcode)
eststo c1

* (2) State FE, interaction: layoff × max_ben
areg delinq_mort i.layoff##c.max_ben_demean year_dum* $state_controls $ind_controls ///
    [pw = weight_ref], a(stcode) cl(stcode)
eststo c2

* (3) State-year FE (absorbing st_year), interaction identified within state-year
areg delinq_mort i.layoff##c.max_ben_demean year_dum* $state_controls $ind_controls ///
    [pw = weight_ref], a(st_year) cl(stcode)
eststo c3

log close



* Output
estadd local hh_controls "Yes" : c1
estadd local sy_controls "Yes" : c1
estadd local st_yr_fe    "Yes" : c1
estadd local styr_fe     "No"  : c1

estadd local hh_controls "Yes" : c2
estadd local sy_controls "Yes" : c2
estadd local st_yr_fe    "Yes" : c2
estadd local styr_fe     "No"  : c2

estadd local hh_controls "Yes" : c3
estadd local sy_controls "—"   : c3
estadd local st_yr_fe    "—"   : c3
estadd local styr_fe     "Yes" : c3

* Output(RTF)
esttab c1 c2 c3 using "/Users/miranaaazzz/desktop/Replication_UI as a Housing Market Stabilizer/Table_4/Table4_replication.rtf", replace ///
    b(2) se(2) ///
    keep(max_ben_demean 1.layoff#c.max_ben_demean 1.layoff) ///
    order(max_ben_demean 1.layoff#c.max_ben_demean 1.layoff) ///
    varlabels( ///
        max_ben_demean "Max Benefit" ///
        1.layoff#c.max_ben_demean "Max Benefit × Layoff" ///
        1.layoff "Layoff" ///
    ) ///
    stats(N r2 hh_controls sy_controls st_yr_fe styr_fe, ///
        fmt(0 2 0 0 0 0) ///
        labels("Observations" "R-squared" ///
               "Household controls" "State-year controls" ///
               "State and year fixed effects" "State-year fixed effects") ///
    ) ///
    addnotes( ///
        "Notes: Linear probability models. Dependent variable is mortgage delinquency (indicator × 100)." ///
        "Max Benefit is measured in $1,000. Standard errors clustered at the state level." ///
        "Home price growth (Case-Shiller/CoreLogic) is proprietary and excluded from the public replication data." ///
        "In column (3), state-by-year fixed effects absorb the Max Benefit main effect." ///
    )

	
	
	
	
	
/********************************************************
*********************************************************
*********************************************************

	Unemployment Insurance as a Housing Market Stabilizer

	FILENAME: UI_sipp_analysis.do

	Analysis of mortgage delinquency and UI benefits generosity using SIPP data between 1991 and 2010.
	
	Results presented in Tables 1, 4, 5, 6, 7 and 8 of paper.
	
	HOUSEHOLD-LEVEL VARIABLES:
	
	weight_ref: sample weight
	delinq_mort: indicator for mortgage delinquency * 100
	evict: indicator for home eviction * 100
	educ_less_hs: indicator for less than high school diploma                 
	educ_hs: indicator for high school diploma only
	educ_somecol: indicator for some college
	educ_col: indicator for college degree      
	educ_grad: indicator for graduate studies beyond college degree        
	layoff: indicator for layoff over prior year
	spouse: indicator for married or living with a partner
	thhtnw: household net worth (in $ millions of 2010 dollars)
	thomeamt: monthly mortgage payment (in dollars)
	max_ben_indiv: maximum UI benefit available based on prior household earnings (in $ thousands)                 
	earnings_max: prior quarterly earnings (maximum among individuals in household)
	earnings_months: number of months with valid household earnings information in quarter prior to one-year mortgage delinquency window                    
	assets_liquid: liquid assets (in $ 100,000)                 
	ltv_win: mortgage loan-to-value ratio, winsorized at 99th percentile
	neg_equity: indicator for negative home equity                 
	neg_equity_120_plus: indicator for mortgage loan-to-value ratio above 120%    
	earnings_total: household earnings in quarter prior to one-year mortgage delinquency window (annualized)
	st_year_layoff: categorical variable indicating state-year-layoff groups
	mortgage_ui: mortgage payment per week as fraction of maximum weekly benefit  

	STATE-LEVEL VARIABLES
	
	stcode: state FIPS code
	year_dum*: indicators for each SIPP Panel year
	st_year: categorical variable indicating state-year groups
	ln_realgdp_percap: log of real GDP per capita
	unemp_rate: unemployment rate
	wages_state: average wages
	cov: union coverage rate
	ui_rr: UI trust fund reserve ratio
	neg_ui_rr: indicator for a negative UI trust fund balance
	wba_max: maximum weekly UI benefit ($ thousands)
	duration_max: maximum number of weeks for which regular UI benefits are paid 
	eb_euc_weeks: maximum number of weeks for which EB and EUC benefits are paid 
	max_ben: wba_max_thousands * duration_max
	max_ben_real: max_ben deflated to 2011 dollars
	max_ben_wages: max_ben / wages_state
	ln_max_ben: ln(max_ben)
	max_ben_eb_euc: wba_max_thousands * eb_euc_weeks
	tur_3mo: prior three month average total unemployment rate in the state

	*note: all derivants of variables above with "_demean" appended are de-meaned relative to mean within various regression sub-samples
	
*********************************************************
*********************************************************
********************************************************/

*** NOTE: We have dropped non-public information on home price growth used
*** in our analysis below. Specifically, we exclude the variable "hpi_growth,"
*** referenced below, which measures the year-over-year growth rate of
*** the Case-Shiller state-level home price index. Our data contract prevents
*** us from publishing the values of the index and the home price growth. Users
*** who obtain the state-level Case-Shiller Indexes from CoreLogic
*** (http://www.corelogic.com/products/corelogic-case-shiller.aspx)
*** can merge those data (by state and year) with ui_econ_analysis.dta and
*** run the code below. 


*** The following global macros are used to identify the covariates that recur across models.
*** We have created one set of controls with state-level variables and another with household-level variables

*global state_controls "unemp_rate ln_realgdp_percap hpi_growth wages_state ui_rr neg_ui_rr union_cov" 
*global ind_controls "i.layoff##c.ltv_win_demean i.layoff##c.neg_equity_demean earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad" 

***We demean maximum UI benefits and any other variables that will be interacted with the layoff indicator. Since the regression sample differs in some models,
***we repeat this demeaning across each subsample. The global macros below adjust the household-level control variables to include the appropriate
***demeaned variables. This is relevant to the loan-to-value ratio and negative equity indicator, both of which are interacted with the layoff indicator.

*Demeaned for subsample pertinent to EB/EUC analysis (SIPP 2008)

*global ind_controlsX "i.layoff##c.ltv_win_demeanX i.layoff##c.neg_equity_demeanX earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad" 

*Demeaned for subsample of single (S) or married (M)

*global ind_controlsS "i.layoff##c.ltv_win_demeanS i.layoff##c.neg_equity_demeanS earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad" 
*global ind_controlsM "i.layoff##c.ltv_win_demeanM i.layoff##c.neg_equity_demeanM earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad" 

*Demeaned for subsample of single (S) or married (M) in EB/EUC analysis period

*global ind_controlsXS "i.layoff##c.ltv_win_demeanXS i.layoff##c.neg_equity_demeanXS earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad" 
*global ind_controlsXM "i.layoff##c.ltv_win_demeanXM i.layoff##c.neg_equity_demeanXM earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad" 

*Demeaned for subsample of low (Alow) or high assets (Ahigh)

*global ind_controlsAlow "i.layoff##c.ltv_win_demeanAlow i.layoff##c.neg_equity_demeanAlow earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad" 
*global ind_controlsAhigh "i.layoff##c.ltv_win_demeanAhigh i.layoff##c.neg_equity_demeanAhigh earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad" 

*Demeaned for subsample of low (Alow) or high assets (Ahigh) in EB/EUC analysis period

*global ind_controlsXAlow "i.layoff##c.ltv_win_demeanXAlow i.layoff##c.neg_equity_demeanXAlow earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad" 
*global ind_controlsXAhigh "i.layoff##c.ltv_win_demeanXAhigh i.layoff##c.neg_equity_demeanXAhigh earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad" 

*Demeaned for subsample of positive equity (PE), negative equity (NE) or deep negative equity (DNE)

*global ind_controlsPE "i.layoff##c.ltv_win_demeanPE i.layoff##c.neg_equity_demeanPE earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad" 
*global ind_controlsNE "i.layoff##c.ltv_win_demeanNE i.layoff##c.neg_equity_demeanNE earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad" 
*global ind_controlsDNE "i.layoff##c.ltv_win_demeanDNE i.layoff##c.neg_equity_demeanDNE earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad" 

*Demeaned for subsample of positive equity (PE), negative equity (NE) or deep negative equity (DNE) in EB/EUC analysis period

*lobal ind_controlsXPE "i.layoff##c.ltv_win_demeanXPE i.layoff##c.neg_equity_demeanXPE earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad" 
*global ind_controlsXNE "i.layoff##c.ltv_win_demeanXNE i.layoff##c.neg_equity_demeanXNE earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad" 
*global ind_controlsXDNE "i.layoff##c.ltv_win_demeanXDNE i.layoff##c.neg_equity_demeanXDNE earnings_total thhtnw educ_hs educ_somecol educ_col educ_grad" 


*** Analysis, organized by the table in the paper where the analysis is presented ********



*** Table 4 - regressions of mortgage delinquency on layoff, regular UI benefits and covariates

*areg delinq_mort max_ben_demean i.layoff year_dum* $state_controls $ind_controls [pw = weight_ref], a(stcode) cl(stcode)
*outreg2 using "UI and Credit/Tables/table4", alpha (0.01, 0.05, 0.10) bdec(2) rdec(3) sdec(2) drop (year_dum* $state_controls $ind_controls) nocons replace 

*areg delinq_mort i.layoff##c.max_ben_demean year_dum* $state_controls $ind_controls [pw = weight_ref], a(stcode) cl(stcode)
*outreg2 using "UI and Credit/Tables/table4", alpha (0.01, 0.05, 0.10) bdec(2) rdec(3) sdec(2) drop (year_dum* $state_controls $ind_controls) nocons append

*areg delinq_mort i.layoff##c.max_ben_demean year_dum* $state_controls $ind_controls [pw = weight_ref], a(st_year) cl(stcode)
*outreg2 using "UI and Credit/Tables/table4", alpha (0.01, 0.05, 0.10) bdec(2) rdec(3) sdec(2) drop (year_dum* $state_controls $ind_controls) nocons append
