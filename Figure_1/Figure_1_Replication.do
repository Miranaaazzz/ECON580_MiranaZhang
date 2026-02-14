*******************************************************
* UI as a Housing Market Stabilizer (Hsu, Matsa, Melzer)
* Replicate Figure 1 (quartiles) + two additional maps
*   (A) Increase in max UIB between 1991 and 2010 (by quartile)
*   (B) Levels of max UIB in 1991 (by quartile)
*   (C) Levels of max UIB in 2010 (by quartile)
*
* Outputs (PNG/PDF):
*   Figures/Figure1_increase_q4_with_AKHI.png/pdf
*   Figures/Figure1_increase_q4_no_AKHI.png/pdf
*   Figures/Figure_add_level1991_q4_with_AKHI.png/pdf
*   Figures/Figure_add_level1991_q4_no_AKHI.png/pdf
*   Figures/Figure_add_level2010_q4_with_AKHI.png/pdf
*   Figures/Figure_add_level2010_q4_no_AKHI.png/pdf
*
* Notes:
*   - Figure 1 does NOT require hpi_growth.
*   - We merge by state FIPS: stcode -> STATEFP (2-digit string).
*   - Quartiles are computed across ALL 51 states (incl. AK/HI).
*******************************************************

version 16.0
clear all
set more off
set scheme s2color

cd "/Users/miranaaazzz/Desktop/Replication_UI as a Housing Market Stabilizer"

capture mkdir "shapefiles_dta"

cap which shp2dta
if _rc ssc install shp2dta, replace

cap which spmap
if _rc ssc install spmap, replace


* Shapefile -> Stata map files (safe to re-run)
shp2dta using "shapefiles/cb_2018_us_state_20m.shp", ///
    database("shapefiles_dta/us_state_db") ///
    coordinates("shapefiles_dta/us_state_coor") ///
    genid(id) replace

* Build state-level series: max_ben1991, max_ben2010, increase
use "ui_econ_analysis.dta", clear
keep if inlist(year, 1991, 2010)
keep stcode year max_ben
reshape wide max_ben, i(stcode) j(year)

rename max_ben1991 max_ben_1991
rename max_ben2010 max_ben_2010

gen d_max_ben = max_ben_2010 - max_ben_1991

label var max_ben_1991 "Maximum UI benefit level (1991)"
label var max_ben_2010 "Maximum UI benefit level (2010)"
label var d_max_ben    "Change in max UI benefit (2010-1991)"

* Merge key
gen STATEFP = string(stcode, "%02.0f")


* Merge with shapefile database (for id + names)
merge 1:1 STATEFP using "shapefiles_dta/us_state_db.dta"
keep if _merge==3
drop _merge

count
assert r(N)==51


* Create quartiles (4 groups) for: increase, 1991 level, 2010 level
* Use xtile (standard quartiles); labels 1..4
xtile q_inc = d_max_ben, nq(4)
xtile q_91  = max_ben_1991, nq(4)
xtile q_10  = max_ben_2010, nq(4)

label define q4lbl 1 "1" 2 "2" 3 "3" 4 "4", replace
label values q_inc q4lbl
label values q_91  q4lbl
label values q_10  q4lbl

label var q_inc "Quartile group (1=lowest, 4=highest): increase"
label var q_91  "Quartile group (1=lowest, 4=highest): level 1991"
label var q_10  "Quartile group (1=lowest, 4=highest): level 2010"

* Sanity checks
tab q_inc, missing
tab q_91,  missing
tab q_10,  missing


* Map style: grayscale quartiles (paper-like)
* 1 -> lightest, 4 -> darkest
local q4colors "gs15 gs11 gs7 gs3"


* A) Figure 1: INCREASE quartiles

* WITH AK/HI
spmap q_inc using "shapefiles_dta/us_state_coor.dta", ///
    id(id) ///
    clmethod(custom) clbreaks(0.5 1.5 2.5 3.5 4.5) ///
    fcolor(`q4colors') ///
    ocolor(black) osize(vthin) ///
    legend( ///
        pos(4) ring(0) ///
        region(lstyle(solid) lcolor(black) fcolor(white)) ///
        symxsize(*2.6) symysize(*2.6) ///
        size(*1.2) ///
        order(1 2 3 4) ///
        label(1 "1") label(2 "2") label(3 "3") label(4 "4") ///
    ) ///
    title("") ///
    note("Figure 1. Geographic distribution of regular state unemployment insurance benefit increases between 1991 and 2010, by quartile.", ///
         size(vsmall)) ///
    graphregion(color(white) margin(2 2 2 2)) ///
    plotregion(margin(2 2 2 2))

graph export "Figure_1/Figures/Figure1_increase_q4_with_AKHI.png", replace width(5000)
graph export "Figure_1/Figures/Figure1_increase_q4_with_AKHI.pdf", replace

* NO AK/HI (exclude only at plotting stage)
spmap q_inc if !inlist(STATEFP,"02","15") using "shapefiles_dta/us_state_coor.dta", ///
    id(id) ///
    clmethod(custom) clbreaks(0.5 1.5 2.5 3.5 4.5) ///
    fcolor(`q4colors') ///
    ocolor(black) osize(vthin) ///
    legend( ///
        pos(4) ring(0) ///
        region(lstyle(solid) lcolor(black) fcolor(white)) ///
        symxsize(*2.6) symysize(*2.6) ///
        size(*1.2) ///
        order(1 2 3 4) ///
        label(1 "1") label(2 "2") label(3 "3") label(4 "4") ///
    ) ///
    title("") ///
    note("Figure 1. Geographic distribution of regular state unemployment insurance benefit increases between 1991 and 2010, by quartile.", ///
         size(vsmall)) ///
    graphregion(color(white) margin(2 2 2 2)) ///
    plotregion(margin(2 2 2 2))

graph export "Figure_1/Figures/Figure1_increase_q4_no_AKHI.png", replace width(5000)
graph export "Figure_1/Figures/Figure1_increase_q4_no_AKHI.pdf", replace



* B) Additional Figure: LEVELS in 1991 (quartiles)

* WITH AK/HI
spmap q_91 using "shapefiles_dta/us_state_coor.dta", ///
    id(id) ///
    clmethod(custom) clbreaks(0.5 1.5 2.5 3.5 4.5) ///
    fcolor(`q4colors') ///
    ocolor(black) osize(vthin) ///
    legend( ///
        pos(4) ring(0) ///
        region(lstyle(solid) lcolor(black) fcolor(white)) ///
        symxsize(*2.6) symysize(*2.6) ///
        size(*1.2) ///
        order(1 2 3 4) ///
        label(1 "1") label(2 "2") label(3 "3") label(4 "4") ///
    ) ///
    title("") ///
    note("Additional Figure. Geographic distribution of regular state unemployment insurance benefit levels in 1991, by quartile.", ///
         size(vsmall)) ///
    graphregion(color(white) margin(2 2 2 2)) ///
    plotregion(margin(2 2 2 2))

graph export "Figure_1/Figures/Figure_add_level1991_q4_with_AKHI.png", replace width(5000)
graph export "Figure_1/Figures/Figure_add_level1991_q4_with_AKHI.pdf", replace

* NO AK/HI
spmap q_91 if !inlist(STATEFP,"02","15") using "shapefiles_dta/us_state_coor.dta", ///
    id(id) ///
    clmethod(custom) clbreaks(0.5 1.5 2.5 3.5 4.5) ///
    fcolor(`q4colors') ///
    ocolor(black) osize(vthin) ///
    legend( ///
        pos(4) ring(0) ///
        region(lstyle(solid) lcolor(black) fcolor(white)) ///
        symxsize(*2.6) symysize(*2.6) ///
        size(*1.2) ///
        order(1 2 3 4) ///
        label(1 "1") label(2 "2") label(3 "3") label(4 "4") ///
    ) ///
    title("") ///
    note("Additional Figure. Geographic distribution of regular state unemployment insurance benefit levels in 1991, by quartile.", ///
         size(vsmall)) ///
    graphregion(color(white) margin(2 2 2 2)) ///
    plotregion(margin(2 2 2 2))

graph export "Figure_1/Figures/Figure_add_level1991_q4_no_AKHI.png", replace width(5000)
graph export "Figure_1/Figures/Figure_add_level1991_q4_no_AKHI.pdf", replace



* C) Additional Figure: LEVELS in 2010 (quartiles)

* WITH AK/HI
spmap q_10 using "shapefiles_dta/us_state_coor.dta", ///
    id(id) ///
    clmethod(custom) clbreaks(0.5 1.5 2.5 3.5 4.5) ///
    fcolor(`q4colors') ///
    ocolor(black) osize(vthin) ///
    legend( ///
        pos(4) ring(0) ///
        region(lstyle(solid) lcolor(black) fcolor(white)) ///
        symxsize(*2.6) symysize(*2.6) ///
        size(*1.2) ///
        order(1 2 3 4) ///
        label(1 "1") label(2 "2") label(3 "3") label(4 "4") ///
    ) ///
    title("") ///
    note("Additional Figure. Geographic distribution of regular state unemployment insurance benefit levels in 2010, by quartile.", ///
         size(vsmall)) ///
    graphregion(color(white) margin(2 2 2 2)) ///
    plotregion(margin(2 2 2 2))

graph export "Figure_1/Figures/Figure_add_level2010_q4_with_AKHI.png", replace width(5000)
graph export "Figure_1/Figures/Figure_add_level2010_q4_with_AKHI.pdf", replace

* NO AK/HI
spmap q_10 if !inlist(STATEFP,"02","15") using "shapefiles_dta/us_state_coor.dta", ///
    id(id) ///
    clmethod(custom) clbreaks(0.5 1.5 2.5 3.5 4.5) ///
    fcolor(`q4colors') ///
    ocolor(black) osize(vthin) ///
    legend( ///
        pos(4) ring(0) ///
        region(lstyle(solid) lcolor(black) fcolor(white)) ///
        symxsize(*2.6) symysize(*2.6) ///
        size(*1.2) ///
        order(1 2 3 4) ///
        label(1 "1") label(2 "2") label(3 "3") label(4 "4") ///
    ) ///
    title("") ///
    note("Additional Figure. Geographic distribution of regular state unemployment insurance benefit levels in 2010, by quartile.", ///
         size(vsmall)) ///
    graphregion(color(white) margin(2 2 2 2)) ///
    plotregion(margin(2 2 2 2))

graph export "Figure_1/Figures/Figure_add_level2010_q4_no_AKHI.png", replace width(5000)
graph export "Figure_1/Figures/Figure_add_level2010_q4_no_AKHI.pdf", replace


	
*******************************************************
* EXTRA: Convergence + Homogeneity checks (State-level)
* Uses the same constructed variables:
*   max_ben_1991, max_ben_2010, d_max_ben
*******************************************************


* Correlation: initial level vs increase
di "=================================================="
di "Correlation between initial level (1991) and increase (2010-1991)"
di "=================================================="
corr max_ben_1991 d_max_ben


matrix C = r(C)
scalar corr_91_inc = C[1,2]
di "corr(max_ben_1991, d_max_ben) = " %6.3f corr_91_inc


* Beta-convergence regression
* d_max_ben = a + b * max_ben_1991 + e
* b < 0 => convergence; b > 0 => divergence/persistence
di "=================================================="
di "Beta-convergence regression: d_max_ben on max_ben_1991"
di "=================================================="
reg d_max_ben max_ben_1991, vce(robust)


* Scatter + fitted line (publication-style)
twoway ///
    (scatter d_max_ben max_ben_1991, ///
        msize(small) ///
        msymbol(O) ///
    ) ///
    (lfit d_max_ben max_ben_1991, ///
        lwidth(medthick) ///
    ), ///
    title("Correlation between Initial Level and Increase") ///
    ytitle("Increase in Max Benefit (1991--2010)") ///
    xtitle("Max Benefit Level in 1991") ///
    legend(order(1 "Increase (2010-1991)" 2 "Fitted values") pos(3) ring(0)) ///
    graphregion(color(white)) ///
    plotregion(margin(2 2 2 2))

graph export "Figure_1/Figures/convergence_scatter.png", replace width(2500)
graph export "Figure_1/Figures/convergence_scatter.pdf", replace


* Homogeneity check: dispersion in 1991 vs 2010
* Compare SD/Var/CV/Range
di "=================================================="
di "Homogeneity check: dispersion in 1991 vs 2010"
di "=================================================="

tabstat max_ben_1991 max_ben_2010, stat(n mean sd var min p10 p50 p90 max) col(stat)

* Coefficient of variation (CV = sd / mean)
quietly summarize max_ben_1991
local mean91 = r(mean)
local sd91   = r(sd)
quietly summarize max_ben_2010
local mean10 = r(mean)
local sd10   = r(sd)

di "CV(1991) = SD/Mean = " %6.3f (`sd91'/`mean91')
di "CV(2010) = SD/Mean = " %6.3f (`sd10'/`mean10')


* Overlay histograms (1991 vs 2010)
summ max_ben_1991
local m91 = r(mean)

summ max_ben_2010
local m10 = r(mean)

twoway ///
    (histogram max_ben_1991, percent width(0.5) lcolor(black) fcolor(none) lwidth(medthick)) ///
    (histogram max_ben_2010, percent width(0.5) lcolor(black) fcolor(none) lpattern(dash) lwidth(medthick)), ///
    xline(`m91', lpattern(solid)) ///
    xline(`m10', lpattern(dash)) ///
    title("Distribution of Maximum UI Benefits: 1991 vs 2010") ///
    xtitle("Maximum UI Benefit Level") ///
    ytitle("Percent of States") ///
    legend(order(1 "1991 (solid)" 2 "2010 (dashed)") pos(3) ring(0)) ///
    graphregion(color(white))

graph export "Figure_1/Figures/homogeneity_hist.png", replace width(2500)
graph export "Figure_1/Figures/homogeneity_hist.pdf", replace
	



