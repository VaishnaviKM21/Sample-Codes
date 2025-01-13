**********************************************************************************************************************
***************************************Exploratory Analysis-1*********************************************************
**********************************************************************************************************************

/*
Notes:
1. q2023 quarter 2 is when the cash transfer took place happened 
2. The data used is the Periodic Labour force survey (PLFS) from 2017 quarter 2 to 2024 quarter 2
3. The data is already combines, cleaned and edited to contain Madhya Pradesh only 
4. Blocks are to be run end to end (preserve to restore)
*/

use "D:\Desktop\RA MP\Edited data.dta", clear // Loading the data 

keep if year==2020 |year==2021 |year==2022 | year== 2023 | year==2024 // Keeping data for required specific years.
keep if sector==1 // Rural only
drop if ps==.r // Dropping observations where there were no revisit
drop if ps==.u // Dropping observations where principal status is missing

*************************Weights*******************************************
gen weights = mlts/100 if nss==nsc // Generating weights based on PLFS recommendation
replace weights=mlts/200 if weights==. 
destring year visit fsu subsample stage2_stratum subblock, replace 

************Wages***************************
gen weekly_hrs_wouldhave_ps=day1_a1_hrs+ day2_a1_hrs+ day3_a1_hrs+ day4_a1_hrs+ day5_a1_hrs+ day6_a1_hrs+ day7_a1_hrs // Weekly hours willing to supply to primary activity.
gen weekly_hrs_wouldhave_ss=day1_a2_hrs+ day2_a2_hrs+ day3_a2_hrs+ day4_a2_hrs+ day5_a2_hrs+ day6_a2_hrs+ day7_a2_hrs // Weekly hours willing to supply to secondary activity
gen weekly_hrs_actual=day1_hrs_total + day2_hrs_total+ day3_hrs_total+ day4_hrs_total+ day5_hrs_total+ day6_hrs_total+ day7_hrs_total // Actual hours worked in a week

*********Genrating variable that signifies quarter of the year************************
gen annual_quarter= 1 if quarter_monotonic==240 | quarter_monotonic==244 |quarter_monotonic==248 |quarter_monotonic==252 |quarter_monotonic==256 
replace annual_quarter= 2 if quarter_monotonic==241 | quarter_monotonic==245 |quarter_monotonic==249 |quarter_monotonic==253 |quarter_monotonic==257 
replace annual_quarter= 3 if quarter_monotonic==242 | quarter_monotonic==246 |quarter_monotonic==250 |quarter_monotonic==254 
replace annual_quarter= 4 if quarter_monotonic==243 | quarter_monotonic==247 |quarter_monotonic==251 |quarter_monotonic==255 

****************Subsidiary Activity Female Labor force participation***************
**Binary variable
gen sflfp =1  if ss_any==1 & sex==2 & age>15 
replace sflfp = 0 if sflfp==. 


*********************T-tests (unweighted)***********************************
*to check if ther are any difference between the quarter when cash transfer was rolled out and the quarter before that

////////////////////////////////////Block//////////////////////////////////////////
  preserve 
  keep if sex==2 // Keeping only female data.
  keep if quarter_monotonic == 252 | quarter_monotonic== 253 // Keeping data for specific quarters.
  ttest weekly_hrs_wouldhave_ps by(quarter_monotonic) //t-test on supplied weekly hours for primary activity by quarter.
  ttest weekly_hrs_wouldhave_ss, by(quarter_monotonic) // t-test on supplied weekly hours for subsidiary activity by quarter.
  ttest weekly_hrs_actual, by(quarter_monotonic) //t-test on actual weekly hours by quarter.
  collapse (mean)weekly_hrs_wouldhave_ps (mean)weekly_hrs_wouldhave_ss (mean)weekly_hrs_actual, by(month) // Collapsing by month and calculating means.
  list 
  restore // Restoring the dataset to its previous state.
///////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////Block//////////////////////////////////////////
  preserve 
  if sex==2 // Keeping data for females.
  bysort quarter_monotonic: sum weekly_hrs_wouldhave_ps 
  bysort quarter_monotonic: sum weekly_hrs_wouldhave_ss
  keep if quarter_monotonic == 250 | quarter_monotonic== 251 //Change of quarters
  ttest weekly_hrs_wouldhave_ps, by(quarter_monotonic) //same t-tests as before
  ttest weekly_hrs_wouldhave_ss, by(quarter_monotonic) 
  ttest weekly_hrs_actual, by(quarter_monotonic) 
  collapse (mean)weekly_hrs_wouldhave_ps (mean)weekly_hrs_wouldhave_ss (mean)weekly_hrs_actual, by(month) // Collapsing by month and calculating means.
  list // Listing the results.
  restore // Restoring the dataset to its previous state.
///////////////////////////////////////////////////////////////////////////////////

**Subsidiary FLFP rate****

////////////////////////////////////Block//////////////////////////////////////////
  preserve
  keep if sex==2
  collapse (mean) sflfp [pw=weights], by(quarter_monotonic sector)
  list

*Addding a red dotted line at the position of "2023q2" on the x-axis
  local target_quarter = 253  

*Line grapg comparing urban and rural subsidiary FLFP
  twoway (line sflfpr quarter_monotonic if sector == 1, lcolor(blue) lpattern(solid) legend(label(1 "Rural"))) /// 
  (line sflfpr quarter_monotonic if sector == 2, lcolor(red) lpattern(solid) legend(label(2 "Urban"))) /// 
  , legend(position(5)) title("Female labour force participation in subsidiary activity", size(small)) /// 
  xtitle("") ytitle("") graphregion(color(white)) plotregion(color(white)) /yscale(range(0 50)) /// 
  xlabel(#15 , labsize(small)) ///    Increase the number of ticks on x-axis to 15
  ylabel(#15, labsize(small)) ///    Increase the number of ticks on y-axis 
  xline(`target_quarter', lcolor(mint) lpattern(dash)) // Add dotted line for "2023q2"

  restore
///////////////////////////////////////////////////////////////////////////////////

*Femabl Labor Force Participation Rate (principal employment)

////////////////////////////////////Block//////////////////////////////////////////
  preserve
  keep if sex==2 //female only
  collapse (mean) flfp [pw=weights], by(quarter_monotonic sector)
  list
* Add a red dotted line at the position of "2023q2" on the x-axis
  local target_quarter = 253  // Replace this with the numeric value for 2023q2 in quarter_monotonic

*Line graph cmparing principal FLFP in urban and rural
  twoway (line sflfpr quarter_monotonic if sector == 1, lcolor(blue) lpattern(solid) legend(label(1 "Rural"))) /// 
  (line sflfpr quarter_monotonic if sector == 2, lcolor(red) lpattern(solid) legend(label(2 "Urban"))) /// 
  , legend(position(5)) title("Female labour force participation in principal activity", size(small)) /// 
  xtitle("") ytitle("") graphregion(color(white)) plotregion(color(white)) /yscale(range(0 70)) /// 
  xlabel(#15 , labsize(small)) ///   
  ylabel(#15, labsize(small)) ///  
  xline(`target_quarter', lcolor(mint) lpattern(dash)) // Add dotted line for "2023q2"

  restore
///////////////////////////////////////////////////////////////////////////////////

* Female labor force Participation rates
////////////////////////////////////Block/////////////////////////////////////
  preserve
  keep if sex==2
  collapse (mean) sflfp (mean) pflfp [pw=weights], by(quarter_monotonic sector)
  list
****Line graph to compare principal and subsidiary participation in urban and rural
  local target_quarter = 253 
  twoway (line sflfpr quarter_monotonic if sector == 1, lcolor(blue) lpattern(solid) legend(label(1 "Rural Subsidiary"))) /// 
   (line pflfpr quarter_monotonic if sector == 1, lcolor(sea) lpattern(solid) legend(label(2 "Rural Principal"))) /// 
  (line sflfpr quarter_monotonic if sector == 2, lcolor(red) lpattern(solid) legend(label(3 "Urban Subsidiary"))) /// 
  (line pflfpr quarter_monotonic if sector == 2, lcolor(maroon) lpattern(solid) legend(label(4 "Urban Principal"))), /// 
  legend(position(6) rows(2) size(small)) xtitle("") ytitle("") graphregion(color(white)) plotregion(color(white)) /// 
  yscale(range(0 60)) xlabel(#15 , labsize(small)) ///   // Increase the number of ticks on x-axis to 15
  ylabel(#15, labsize(small)) ylabel(0 50, ang(0) labsize(small)) /// 
  xlabel(, labsize(small)) xline(`target_quarter', lcolor(mint) lpattern(dash))  // Add dotted line for 2023 quarter 2	  
  restore
///////////////////////////////////////////////////////////////////////////////////


**Overall Finding: Female participation is higher in subsidiary employment. 
//Why is the participation in subsidiary higher than principal? Further analysis.


**********************************************************************************************************************************
***************************************Exploratory Analysis-2*********************************************************************
**********************************************************************************************************************************


*******************Trends my marital status******************

////////////////////////////////////Block/////////////////////////////////////
  preserve
  keep if sex==2 //female only
  destring marital, replace
  collapse (mean) sflfp (mean) pflfp [pw=weights], by(quarter_monotonic sector marital)
  list

  **line graph comparing women of different marital status in rural areas
  local target_quarter = 253  // 2023 quarter 2
  twoway (line sflfpr quarter_monotonic if sector == 1 & marital==1, lcolor(blue) lpattern(solid) legend(label(1 "Subsidiary- Unmarried"))) /// 
  (line pflfpr quarter_monotonic if sector == 1 & marital==1, lcolor(sea) lpattern(solid) /// 
  legend(label(2 "Principal - Unmarried"))) /// 
  (line sflfpr quarter_monotonic if sector == 1 & marital==2, lcolor(red) lpattern(solid) /// 
  legend(label(3 "Subsidiary - Married "))) /// 
  (line pflfpr quarter_monotonic if sector == 1 & marital==2, lcolor(maroon) lpattern(solid) /// 
  legend(label(4 "Principal - Married") )), legend(position(6) rows(2) size(small)) /// 
  xtitle("") ytitle("") graphregion(color(white)) plotregion(color(white)) /// 
  yscale(range(0 60)) xlabel(#15 , labsize(small)) ///   // Increase the number of ticks on x-axis to 15
  ylabel(#15, labsize(small)) ylabel(0 60, ang(0) labsize(small)) /// 
  xlabel(, labsize(small)) xline(`target_quarter', lcolor(mint) lpattern(dash))  // dotted line for 2023 quarter 2	
  restore
///////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////Block/////////////////////////////////////////
  preserve
  keep if sex==2 //female only
  destring marital, replace
  collapse (mean) sflfp (mean) pflfp [pw=weights], by(quarter_monotonic sector marital)
  list

  **Line graph comparing women of different marital status in Urban areas
  local target_quarter = 253 
  twoway (line sflfpr quarter_monotonic if sector == 2 & marital==1, lcolor(blue) lpattern(solid) legend(label(1 "Subsidiary- Unmarried"))) /// 
  (line pflfpr quarter_monotonic if sector == 2 & marital==1, lcolor(sea) lpattern(solid) legend(label(2 "Principal - Unmarried")))  /// 
  (line sflfpr quarter_monotonic if sector == 2 & marital==2, lcolor(red) lpattern(solid) legend(label(3 "Subsidiary - Married "))) /// 
  (line pflfpr quarter_monotonic if sector == 2 & marital==2, lcolor(maroon) lpattern(solid) legend(label(4 "Principal - Married"))), /// 
  legend(position(6) rows(2) size(small)) /// 
  xtitle("") ytitle("") graphregion(color(white)) plotregion(color(white)) /// 
  yscale(range(0 60)) xlabel(#15 , labsize(small)) ///   // Increase the number of ticks on x-axis to 15
  ylabel(#15, labsize(small)) ylabel(0 60, ang(0) labsize(small)) /// 
  xlabel(, labsize(small)) xline(`target_quarter', lcolor(mint) lpattern(dash))  // dotted line for 2023 quarter 2	
  restore
///////////////////////////////////////////////////////////////////////////////////

********** Analysis of Wages*****************

*Adding all wages in a month
gen monthly_principal_wage=monthly_wage_act1+earn_30day_selfempl+earn_30day_wage
gen monthly_subsidiary_wage=monthly_wage_act2+earn_30day_selfempl+earn_30day_wage

////////////////////////////////////Block//////////////////////////////////////////
  preserve
  keep if sex==2
  collapse (mean) monthly_principal_wage (mean) monthly_subsidiary_wage [pw=weights], by(quarter_monotonic sector)
  local target_quarter = 253

  ***Line graph of female wages over quarters by sector and type of employment
  twoway (connect monthly_principal_wage quarter_monotonic if sector==1, legend(label(1 "Rural principal activity wage")) msize(0.6)) /// 
  (connect monthly_principal_wage quarter_monotonic if sector==2, legend(label(2 "Urban principal activity wage")) msize(0.6)) /// 
  (connect monthly_subsidiary_wage quarter_monotonic if sector==1, legend(label(3 "Rural subsidiary activity wage")) msize(0.6)) /// 
  (connect monthly_subsidiary_wage quarter_monotonic if sector==2, legend(label(4 "Urban subsidiary activity wage")) msize(0.6)) /// 
  , legend(position(6) rows(2) size(small)) title("Female wages over time", size(small)) xtitle("") ytitle("") /// 
  graphregion(color(white)) plotregion(color(white)) yscale(range(0 60)) ylabel(#15) /// 
  xlabel(#15, labsize(small)) ylabel(#10, labsize(small)) xline(`target_quarter', lcolor(mint) lpattern(dash)) //adding a reference line for 2023 quarter 2

  restore
///////////////////////////////////////////////////////////////////////////////////

***************Age wise Analysis**************

//creating age bins
gen age_bin = floor(age / 5) * 5
label define age_bins 0 "0-4" 5 "5-9" 10 "10-14" 15 "15-19" 20 "20-24" 25 "25-29" 30 "30-34" 35 "35-39" 40 "40-44" /// 
45 "45-49" 50 "50-54" 55 "55-59" 60 "60-64" 65 "65-69" 70 "70-74" 75 "75-79" 80 "80-84" 85 "85-89" 90 "90-94" 95 "95-99" 100 "100-104"

bysort sex quarter_monotonic: tab age_bin flfp, missing //tabulating female LFP by age_bin
**Generating a new variable that gives rate of participation
bysort age_bin sex quarter_monotonic: egen total_flfp = total(flfp)  // total in each group
bysort age_bin sex quarter_monotonic: egen count_flfp = count(flfp) // labor force participants in each group
gen prop_flfp_age = total_flfp / count_flfp // proprotion of participation
list age_bin sex quarter_monotonic total_flfp count_flfp prop_flfp_age

*Line graphs for each age bin shwoing participation in principal activity over the quarters
twoway (line prop_flfp_age quarter_monotonic if sex == 2 & age>=15 & age <75 ), /// 
by(age_bin, title("Proportion of FLFP for Women by Age Group") /// 
col(4) /// Number of columns in the panel grid
note("Each panel represents a different age bin") /// 
legend(off)) xtitle("Quarter (Monotonic)") ytitle("Proportion of FLFP") /// 
xlabel(, grid) ylabel(, grid) 

////////////////////////////////////Block//////////////////////////////////////////
  preserve
  bysort age_bin sex quarter_monotonic: egen total_sflfp = total(sflfp)
  bysort age_bin sex quarter_monotonic: egen count_sflfp = count(sflfp)
  gen prop_sflfp_age = total_sflfp / count_sflfp
  list age_bin sex quarter_monotonic total_sflfp count_sflfp prop_sflfp_age

  *Line graphs for each age bin showing participation in subsidiary activity over the quarters
  twoway (line prop_sflfp_age quarter_monotonic if sex == 2 & age>=15 & age <75), /// 
  by(age_bin, title("Proportion of FLFP for Women by Age Group") /// 
  col(4) /// Number of columns in the panel grid
  note("Each panel represents a different age bin") /// 
  legend(off)) xtitle("Quarter (Monotonic)") ytitle("Proportion of FLFP") /// 
  xlabel(, grid) ylabel(, grid)
  restore
///////////////////////////////////////////////////////////////////////////////////

******************Age by decade**************

*creating new bins by decades and redoing the same graphs
drop age_bin prop_flfp_age total_flfp count_flfp
gen age_bin = .
replace age_bin = 1 if age < 15
replace age_bin = 2 if age >= 15 & age <= 20
replace age_bin = 3 if age > 20 & age <= 30
replace age_bin = 4 if age > 30 & age <= 40
replace age_bin = 5 if age > 40 & age <= 50
replace age_bin = 6 if age > 50 & age <= 60
replace age_bin = 7 if age > 60

label define age_bin_label 1 "<15" 2 "15-20" 3 "20-30" 4 "30-40" 5 "40-50" 6 "50-60" 7 ">60"
label values age_bin age_bin_label

bysort sex quarter_monotonic: tab age_bin flfp , missing // checking the raw numbers for participation in each age group
**Generating a new variable that gives rate of participation
bysort age_bin sex quarter_monotonic: egen total_flfp = total(flfp)  // total in each group
bysort age_bin sex quarter_monotonic: egen count_flfp = count(flfp) // labor force participants in each group
gen prop_flfp_age = total_flfp / count_flfp // proprotion of participation
list age_bin sex quarter_monotonic total_flfp count_flfp prop_flfp_age

local target_quarter = 253  // 2023 quarter 2
twoway (line prop_flfp_age quarter_monotonic if sex == 2 & sector==1), /// 
by(age_bin, title("Proportion of FLFP by Age Group (Principal rural)") /// 
col(4) /// Number of columns in the panel grid
note("Each panel represents a different age bin") legend(off)) /// 
xtitle("Quarter (Monotonic)") ytitle("Proportion of FLFP") xlabel(, grid) ylabel(, grid) /// 
xline(`target_quarter', lcolor(mint) lpattern(dash))  //reference line for 2023 quarter 2

**Repeating the same for subsidiary employment 
////////////////////////////////////Block//////////////////////////////////////////
  preserve
  *generating a new variable that shows rate of participation
  bysort age_bin sex quarter_monotonic: egen total_sflfp = total(sflfp) // total in each age group
  bysort age_bin sex quarter_monotonic: egen count_sflfp = count(sflfp) // participants in each group
  gen prop_sflfp_age = total_sflfp / count_sflfp // subsidiary rate of participation
  list age_bin sex quarter_monotonic total_sflfp count_sflfp prop_sflfp_age
  local target_quarter = 253 // 2023 quarter 2

  *line graph showing trends in subsidiary participation over quarters for each age group 
  twoway (line prop_sflfp_age quarter_monotonic if sex == 2 & sector==1), /// 
  by(age_bin, title("Proportion of FLFP by Age Group (Subsidiary rural)") /// 
  col(4) /// Number of columns in the panel grid
  note("Each panel represents a different age bin") legend(off)) /// 
  xtitle("Quarter (Monotonic)") ytitle("Proportion of FLFP") /// 
  xlabel(, grid) ylabel(, grid) /// 
  xline(`target_quarter', lcolor(mint) lpattern(dash)) // reference line for 2023 quarter 2
  restore
///////////////////////////////////////////////////////////////////////////////////


**********************************************************************************************************************************
***************************************Exploratory Analysis-3*********************************************************************
**********************************************************************************************************************************

keep if sector==1 // rural only

**generating quarter variable (4 annual quarters from 8 bi-annual quarters)
gen annual_quarter = 1 if quarter == 3 | quarter == 7
replace annual_quarter = 2 if quarter == 4 | quarter == 8
replace annual_quarter = 3 if quarter == 1 | quarter == 5
replace annual_quarter = 4 if quarter == 2 | quarter == 6

gen treatment = (quarter_monotonic>=254) // Quarter3 of 2023 and above takes the value 1 (after the launch of scheme)
label define treat_lbl 0 "Before LBY" 1 "After LBY" // Assigning the label to the treatment variable
label values treatment treat_lbl 
destring sex treatment annual_quarter year, replace

gen either= (has_ss==1 | flfp==1) //Generaing a new variable that takes value 1 if person is employed either in principal or subsidiary activity


**********************************************Fixed Effect Models***************************************

***************Model 1 (No covariates)*****************************
//Dependent Variable: Participation in Principal Activity
logit flfp treatment##i.sex i.annual_quarter i.year [pw= weights] //interacting treatment with gender with quarter and annual fixed effects
eststo principal: margins treatment##sex //marginal effects
eststo principal_1: margins, dydx(*) //storing the output

*************Model 2 (No covariates)*******************
//Dependent Variable: Participation in Subsidiary Activity
logit has_ss treatment##i.sex i.annual_quarter i.year [pw= weights] //interacting treatment with gender with quarter and annual fixed effects
eststo subsidiary: margins treatment##i.sex //marginal effects
eststo subsidiary_1: margins, dydx(*) //storing the output

*************Model 3 (With covariates)*******************
//Dependent Variable: Participation in Primary Activity. Includes covariates
logit flfp treatment##i.sex i.annual_quarter i.year age i.marital i.hh_religion hh_size i.hh_social_group i.gen_edu [pw= weights]
eststo principal: margins treatment##sex //marginal effects
eststo principal_2: margins, dydx(*) //storing the output

*************Model 4 (With covariates)*******************
//Dependent Variable: Participation in Subsidiary Activity. Includes covariates
logit has_ss treatment##i.sex i.annual_quarter i.year age i.marital i.hh_religion hh_size i.hh_social_group i.gen_edu [pw= weights]
eststo subsidiary: margins treatment##i.sex //marginal effects
eststo subsidiary_2: margins, dydx(*) //storing the output

*Exporitng
esttab principal_1 subsidiary_1 principal_2 subsidiary_2 using margins_output.txt, se label tex append ///
title("Predictive Margins") varwidth(25) compress //exporting the two results to LaTeX


*************Model 5 (No covariates)*******************
//Dependent Variable: Participation in both principal and subsidiary (intersection).
//////////////////Block/////////////////////////////////////
preserve
gen both= 0 if has_ss==1 | flfp==1
replace both = 1 if has_ss==1 & flfp==1
drop if both==. //Drops Non participants
logit both treatment##i.sex i.annual_quarter i.year [pw= weights] //interacting treatment with gender with quarter and annual fixed effects
eststo both_1: margins treatment##i.sex //marginal effects
eststo both_1: margins, dydx(*) //storing the output
restore
////////////////////////////////////////////////////////////

*************Model 6 (With Covariates)*******************
//Dependent Variable: Participation in both (intersection). Includes covariates
preserve
gen both= 0 if has_ss==1 | flfp==1
replace both = 1 if has_ss==1 & flfp==1
drop if both==. //Drops Non participants
logit both treatment##i.sex i.annual_quarter i.year age i.marital i.hh_religion hh_size i.hh_social_group i.gen_edu  [pw= weights] //interacting treatment with gender with quarter and annual fixed effects
eststo both_2: margins treatment##i.sex //marginal effects
eststo both_2: margins, dydx(*) //storing the output
restore

*************Model 7 (No covariates)*******************
//Dependent Variable: Participation in either principal or subsidiary (Union)
logit either treatment##i.sex i.annual_quarter i.year [pw= weights] //interacting treatment with gender with quarter and annual fixed effects
eststo either_1: margins treatment##i.sex //marginal effects
eststo either_1: margins, dydx(*) //storing the output

*************Model 6 (With Covariates)*******************
//Dependent Variable: Participation in either principal or subsidiary (Union). Includes covariates
logit either treatment##i.sex i.annual_quarter i.year i.marital i.hh_religion hh_size i.hh_social_group i.gen_edu  [pw= weights]
eststo either_2: margins treatment##i.sex //marginal effects
eststo either_2: margins, dydx(*) //storing the output

*Exporitng
esttab both_1 either_1 both_2 either_2 using margins_output_1.txt, se label tex append ///
title("Predictive Margins") varwidth(25) compress //exporting the two results to LaTeX
