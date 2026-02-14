*******************************************************
* UI as a Housing Market Stabilizer (Hsu, Matsa, Melzer)
* Figure 1 replication (PUBLIC data version)
*
* Figure 1: Geographic distribution of regular state UI
* benefit increases between 1991 and 2010, by quantile.
*
* Inputs:
*   1) ui_econ_analysis.dta  (state-year panel)
*   2) Census state shapefile: cb_2018_us_state_20m.shp
*
* Key points:
*   - Figure 1 does NOT require hpi_growth.
*   - d_max_ben = max_ben(2010) - max_ben(1991)
*   - Custom bins with exact counts (TOTAL=51):
*       1: 9  | 2: 12 | 3: 6 | 4: 9 | 5: 15
*   - DO NOT drop AK/HI from dataset before merge.
*     Exclude only at plotting stage for "no AK/HI" map.
*******************************************************

version 16.0
clear all
set more off


cd "/Users/miranaaazzz/Desktop/Replication_UI as a Housing Market Stabilizer"

capture mkdir "Figures"
capture mkdir "shapefiles_dta"

* Packages
cap which shp2dta
if _rc ssc install shp2dta, replace

cap which spmap
if _rc ssc install spmap, replace


* Shapefile -> Stata map files (safe to re-run)
shp2dta using "shapefiles/cb_2018_us_state_20m.shp", ///
    database("shapefiles_dta/us_state_db") ///
    coordinates("shapefiles_dta/us_state_coor") ///
    genid(id) replace


* Compute benefit change 1991 -> 2010
use "ui_econ_analysis.dta", clear
keep if inlist(year, 1991, 2010)
keep stcode year max_ben

reshape wide max_ben, i(stcode) j(year)

gen d_max_ben = max_ben2010 - max_ben1991
label var d_max_ben "Change in maximum UI benefits, 1991-2010"

* Merge key: 2-digit state FIPS as string
gen STATEFP = string(stcode, "%02.0f")


* Merge with shapefile database (for id + names)
merge 1:1 STATEFP using "shapefiles_dta/us_state_db.dta"
keep if _merge==3
drop _merge


* Custom bins with exact counts (requires TOTAL=51)
*    1:9, 2:12, 3:6, 4:9, 5:15  (sum=51)
count
di as txt "Merged sample size = " r(N)

assert r(N)==51

* Hard sort to avoid ties/averaged ranks messing up exact counts
sort d_max_ben STATEFP
gen r = _n
label var r "Rank of d_max_ben (ascending)"

gen q5 = .
replace q5 = 1 if r <= 9
replace q5 = 2 if inrange(r, 10, 21)     // 9 + 12 = 21
replace q5 = 3 if inrange(r, 22, 27)     // +6 = 27
replace q5 = 4 if inrange(r, 28, 36)     // +9 = 36
replace q5 = 5 if inrange(r, 37, 51)     // remaining 15

label define q5lbl 1 "1" 2 "2" 3 "3" 4 "4" 5 "5", replace
label values q5 q5lbl
label var q5 "Custom quantile groups (9/12/6/9/15)"

* Sanity check exact counts
tab q5, missing


* Export a ranking table (helps diagnose "some states differ")
preserve
    keep STATEFP STUSPS NAME d_max_ben r q5
    sort d_max_ben
    export delimited using "Figure_1/Figure_1_state_ranking_customcounts.csv", replace
restore


* Draw maps
* IMPORTANT: lock classes to integer codes so legend never shifts
* clbreaks: (0.5,1.5,2.5,3.5,4.5,5.5)
*
* Grayscale like paper:
*     1 -> white (gs15)
*     2 -> very light gray (gs12)
*     3 -> medium gray (gs9)
*     4 -> darker gray (gs6)
*     5 -> darkest (gs3)


* Version A: WITH AK/HI
spmap q5 using "shapefiles_dta/us_state_coor.dta", ///
    id(id) ///
    clmethod(custom) clbreaks(0.5 1.5 2.5 3.5 4.5 5.5) ///
    fcolor(gs15 gs12 gs9 gs6 gs3) ///
    ocolor(black) osize(vthin) ///
    legend( ///
        pos(4) ring(0) ///
        region(lstyle(solid) lcolor(black) fcolor(white)) ///
        symxsize(*2.6) symysize(*2.6) ///
        size(*1.2) ///
        order(1 2 3 4 5) ///
        label(1 "1") label(2 "2") label(3 "3") label(4 "4") label(5 "5") ///
    ) ///
    title("") ///
    note("Figure 1. Geographic distribution of regular state unemployment insurance benefit increases between 1991 and 2010, by quantile.", ///
         size(vsmall)) ///
    graphregion(color(white) margin(2 2 2 2)) ///
    plotregion(margin(2 2 2 2))

graph export "Figure_1/Figures/Figure1_same_with_AKHI.png", replace width(5000)
graph export "Figure_1/Figures/Figure1_same_with_AKHI.pdf", replace


* Version B: NO AK/HI (exclude only at plotting stage)
spmap q5 if !inlist(STATEFP,"02","15") using "shapefiles_dta/us_state_coor.dta", ///
    id(id) ///
    clmethod(custom) clbreaks(0.5 1.5 2.5 3.5 4.5 5.5) ///
    fcolor(gs15 gs12 gs9 gs6 gs3) ///
    ocolor(black) osize(vthin) ///
    legend( ///
        pos(4) ring(0) ///
        region(lstyle(solid) lcolor(black) fcolor(white)) ///
        symxsize(*2.6) symysize(*2.6) ///
        size(*1.2) ///
        order(1 2 3 4 5) ///
        label(1 "1") label(2 "2") label(3 "3") label(4 "4") label(5 "5") ///
    ) ///
    title("") ///
    note("Figure 1. Geographic distribution of regular state unemployment insurance benefit increases between 1991 and 2010, by quantile.", ///
         size(vsmall)) ///
    graphregion(color(white) margin(2 2 2 2)) ///
    plotregion(margin(2 2 2 2))

graph export "Figure_1/Figures/Figure1_same_no_AKHI.png", replace width(5000)
graph export "Figure_1/Figures/Figure1_same_no_AKHI.pdf", replace

	
	
	
	