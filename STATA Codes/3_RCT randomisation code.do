*********************************************************************************************************
**********************************Randomization-1********************************************************
***************************Cleaning and preparing the data***********************************************

clear 
import delimited "D:\Downloads\Unit level data of MIS report 78th round\ms51l01.TXT" //Importing Block 1 MIS data
***Data extraction from a single variable
//(name signifies the variable)
gen identification = substr(v1,1,32) //household identification
gen sector = substr(v1,12,1) //sector (rural / urban)
gen district = substr(v1,16,2) 
gen nss_region = substr(v1,13,3)
gen state_code = substr(v1,13,2)
save "D:\Downloads\Unit level data of MIS report 78th round\level1.dta",replace

******************************************************************************************************************
clear
import delimited "D:\Downloads\Unit level data of MIS report 78th round\ms51l03.TXT" //Importing Block 3 MIS data
gen identification = substr(v1,1,32)
gen hh_size = substr(v1,33,2)
gen religion = substr(v1,35,1)
gen social_group = substr(v1,36,1)

***Data extraction from a single variable
//(name signifies the variable, commented if name is unclear)
gen fsu_serial_no = substr(v1, 1, 5) 
gen round = substr(v1, 6, 2) // round of survey
gen sample = substr(v1, 11, 1) //survey sample number
gen sector = substr(v1, 12, 1) //urban/rural
gen nss_region = substr(v1, 13, 3)
gen district = substr(v1, 16, 2)
gen stratum = substr(v1, 18, 2) 
gen sub_stratum = substr(v1, 20, 2)
gen sub_round = substr(v1, 22, 1)
gen fod_sub_region = substr(v1, 23, 4)
gen sample_sub_div = substr(v1, 27, 3)
gen second_stage_stratum = substr(v1, 30, 1)
gen sample_hhld_no = substr(v1, 31, 2) //household number
gen informant_sl_no = substr(v1, 33, 2) //person number
gen response_code = substr(v1, 35, 1) 
gen survey_code = substr(v1, 36, 1)
gen substitution_code = substr(v1, 37, 1)
gen usual_consumer_expenditure = substr(v1, 39, 8) //monthly consumption expenditure
gen exp_on_household_durbales = substr(v1, 71, 8) //monthly expenditure on household durables
gen land_owned = substr(v1, 37, 2) //amount of land owned
gen access_to_hh_bathroom = substr(v1, 109, 1) //Access to bathroom - categorical
gen hand_wash_availability = substr(v1, 110, 1) //Type of handwash facility- categorical
gen distance_to_water= substr(v1, 102, 1) //Distance to nearest water facility- categorical (ranges)
gen access_to_latrine = substr(v1,106,1) 
gen type_of_latrine = substr(v1,107,2) //TYpe of latrine accesible- categorical
gen identification = substr(v1,1,32) //id to merge
save "D:\Downloads\Unit level data of MIS report 78th round\level3.dta",replace

************************************************************************************************
**Merging Extracted Data from the two blocks
use "D:\Downloads\Unit level data of MIS report 78th round\level1.dta", clear

merge 1:1 identification using "D:\Downloads\Unit level data of MIS report 78th round\level3.dta"
keep if _m==3
drop _m

gen state_dist=state_code+district
keep if state_code == "09" // Keep Uttar Pradesh only. Chosen based on previous analysis

destring sector, replace
keep if sector==1 //Rural- the focus of the study is rural areas

destring state_dist, replace
merge m:1 state_dist using "D:\Desktop\Multiplier\Data merging\DistrnamesandCodesNSS.dta" //merging with NSS district names as MIS only has numbers
keep if _m ==3
destring access_to_latrine, replace

*Creating a new variable for different types of latrines
gen exclusive_household_use = (access_to_latrine == 1)  // Exclusive use of household
gen common_use_building = (access_to_latrine == 2)      // Common use of households in the building
gen public_use_no_payment = (access_to_latrine == 3)    // Public/community use without payment
gen public_use_with_payment = (access_to_latrine == 4)  // Public/community use with payment
gen other_access = (access_to_latrine == 9)             // Other access
gen no_access = (access_to_latrine == 5)                // No access to latrine

destring religion, replace
gen hindus = (religion == 1) //binary variable for hindus
gen muslims = (religion==2)  //binary variable for muslims

* Generate binary variables for each distance to water category
destring distance_to_water, replace
gen within_dwelling_water = (distance_to_water == 1)
gen outside_but_in_premises_water = (distance_to_water == 2)
gen water_less_than_0_2km = (distance_to_water == 3)
gen water_0_2_to_0_5km = (distance_to_water == 4)
gen water_0_5_to_1_0km = (distance_to_water == 5)
gen water_1_0_to_1_5km = (distance_to_water == 6)
gen water_1_5km_or_more = (distance_to_water == 7)

****************************************Graphs********************************

////////////////////Block///////////////////////////
preserve
* Collapse by block, calculating the mean (proportion) of each latrine type
collapse (mean) exclusive_household_use common_use_building public_use_no_payment /// //collapsing at a district level
public_use_with_payment other_access no_access within_dwelling_water hindus outside_but_in_premises_water water_1_5km_or_more, by(block district state_dist  districtname)
list districtname no_access hindus
* Scatter plot with quadratic fit of access to latrines against proportion of hindu population
*No access
twoway (scatter no_access hindus if hindus>0 & hindus<1) /// //range imposed to eliminate corrupted observations
(qfit no_access hindus  if hindus>0 & hindus<1)
*HH access
twoway (scatter exclusive_household_use hindus if hindus>0 & hindus<1) /// //range imposed to eliminate corrupted observations
(qfit exclusive_household_use hindus  if hindus>0 & hindus<1)
*Communal Latrines
twoway (scatter common_use_building hindus if hindus>0 & hindus<1) /// //range imposed to eliminate corrupted observations
(qfit common_use_building hindus  if hindus>0 & hindus<1)
*Public latrines
twoway (scatter public_use_no_payment hindus if hindus>0 & hindus<1) /// //range imposed to eliminate corrupted observations
(qfit public_use_no_payment hindus  if hindus>0 & hindus<1)
*paid pubic latrines
twoway (scatter public_use_with_payment hindus if hindus>0 & hindus<1) /// //range imposed to eliminate corrupted observations
(qfit epublic_use_with_payment hindus  if hindus>0 & hindus<1)
//1088 sub_stratum total rural blocks
restore
//////////////////////////////////////////////////

////////////////////Block///////////////////////////
preserve
collapse (mean) hindus muslims, by(district state_dist  districtname)
list districtname hindus
restore
//////////////////////////////////////////////////

save "D:\Desktop\Yale\Stats for business and society\Multiple indicators dataset.dta", replace

*******************************Using different dataset (NFHS)************************
import excel "D:\Downloads\NSS_78th_Layout_Sch_5.1_mult_post.xls", sheet("Sheet2") firstrow clear //importing NFHS data

**Repeating the graphs using NFHS to verify the trends
* Scatter plot 
twoway (scatter Proportionwithoutaccesstolat ProportionofHindus) ///  //no access to latrines against proportion of hindu population
(line fitted_y ProportionofHindus), legend(off) ///
title("Exponential Fit of Proportionwithoutaccesstolat vs ProportionofHindus") 
*exponential fit
twoway (qfitci  Proportionwithoutaccesstolat ProportionofHindus) /// //no access to latrines against proportion of hindu population
(scatter Proportionwithoutaccesstolat ProportionofHindus), legend(off) ///
title("Proportion of Hindus and Access to latrines")

**********************************************************************************************************
**********************************Randomization-2*********************************************************
*****************************Conducting Randomisation*****************************************************


use "D:\Desktop\Yale\Stats for business and society\Multiple indicators dataset.dta", clear //bring back MIS data


/* We find the following from preliminary analysis 
 We do not have information about who uses and who does not. So for the power calc, I will make an assumption that 
1. 63% of all people are using household and specifically pit latrines. 
2. ~1% of them have access to sewer systems. This means that 100-(63+26+1)~10% are using other means, primarily open defecation. 

We have two set of treatments
1. Information campaign
2. Information Campaign with a religious narrative 

Assmuption: Variance is the same. The information campaign will increase the usage by 5% overall because the entire 10% claims to have access. Assuming none of them use it, we check power with baseline 63% 
Assumption, everyone with a personal latrine are using it
*/

/*
I want to currently look at four districts in Uttar Pradesh. These are chosen through a series checks and tests which are not part of this do file.
Districts: Fatehpur, Prayagraj, Jaunpur, and Kaushumbi in Uttar Pradesh.
42,44,45,64
*/

destring distrcode, replace
keep if distrcode == 42 | distrcode == 44 | distrcode == 45 | distrcode == 64

////////////////////Block///////////////////////////
preserve
destring block, replace
sort block district
duplicates drop block, force
collapse (count) block, by (districtname) 
list districtname block //to check the number of blocks in each of the four district
restore
//////////////////////////////////////////////////

////////////////////Block///////////////////////////
preserve
* Calculating the mean (proportion) of each latrine type by block
collapse (mean) exclusive_household_use common_use_building public_use_no_payment ///
public_use_with_payment other_access no_access within_dwelling_water hindus outside_but_in_premises_water water_1_5km_or_more, by(block districtname district state_code)

* Set the seed for reproducibility
set seed 12345

* generating a random number for each observation
gen random_num = runiform()

* Sort by district and social_group to randomize within each strata
bysort district (random_num): gen group = .

* Within each district and social_group, blocks are divided into 3 equal groups
bysort district: replace group = 1 if _n <= _N/3
bysort district: replace group = 2 if _n > _N/3 & _n <= 2*_N/3
bysort district: replace group = 3 if _n > 2*_N/3

label define group_lbl 1 "Treatment 1" 2 "Treatment 2" 3 "Control" //Labelling the groups
label values group group_lbl

* Checking the distribution of groups by district and social_group
tabulate district group 

save "D:\Desktop\Yale\Stats for business and society\random_groups_data_with_social_group.dta", replace //randomisation data saved
restore
//////////////////////////////////////////////////


**********************************************************************************************************
**********************************Randomization-3*********************************************************
********************Balance tests for religion and social group*******************************************

use "D:\Desktop\Yale\Stats for business and society\Multiple indicators dataset.dta", clear // bringing back full MIS data
drop _m

merge m:1 block using "D:\Desktop\Yale\Stats for business and society\random groups data.dta" //merge with collapsed and randomised data

rename group treatment
destring hh_size, replace 

*Test 1: Compare means for continuous variables

* Overlay kernel density plots for hh_size by treatment group
twoway (kdensity hh_size if treatment == 1, color(blue) lwidth(medium)) (kdensity hh_size if treatment == 2, color(red) lwidth(medium)) (kdensity hh_size if treatment == 3, color(green) lwidth(medium))

* Test 2: Compare proportions for categorical variables
tabulate religion treatment, chi2
tabulate social_group treatment, chi2

* Test 3: Graphical tests
graph bar (percent) religion, over(treatment) //Bar plot for religion variable by treatment group
graph bar (percent) social_group, over(treatment) //Bar plot for religion variable by treatment group


tabulate religion treatment, exact

* Post-hoc pairwise comparisons if the Chi-square test is significant
pwcompare treatment, mcompare(bonferroni)

* Frequency distribution of religion by treatment group
tabulate religion treatment

* Frequency distribution of social_group by treatment group
tabulate social_group treatment

***********Mahalanobis Balance test done on R*************

