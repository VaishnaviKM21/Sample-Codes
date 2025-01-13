********************************************************************************************************************************************************
********************************Part 1: Using Cleaned data to create a new variable based on vulnerability**********************************************
********************************************************************************************************************************************************


use "D:\Desktop\PLFS\PLFS 2022-2023\MergedV1.dta", clear  // Loading the dataset 

/* 
household type: 
    for rural areas: self-employed in: agriculture-1, non-agriculture -2; regular wage/salary earning-3, 
                     casual labour in: agriculture-4, non-agriculture -5; others -9. 
    for urban areas: self-employed-1, regular wage/salary earning-2, casual labour -3, others -9. 
*/

gen person_id = id + person_no  // Generate a unique person identifier by combining 'id' and 'person_no'
duplicates tag person_id, gen(dup)  // Tagging duplicates based on the unique 'person_id'
tab dup  // Display the duplicates

destring household_type sector, replace  // Convert variables to numeric values

drop if household_type == 1 | household_type == 9  // Drop self-employed and other category workers based on 'household_type'
drop if sector == 1 & household_type == 2 | sector == 1 & household_type == 4  // Drop rural non-agriculture households

*Type of employment: 1= Salaried, 2= Casual labor
// Generate a new variable 'type_employment' based on 'household_type' and 'sector'
gen type_employment = 1 if household_type == 2 & sector == 2  // Salaried workers in urban areas (sector 2)
replace type_employment = 1 if household_type == 3 & sector == 1  // Salaried workers in rural areas (sector 1)
replace type_employment = 2 if household_type == 3 & sector == 2  // Casual labor in urban areas (sector 2)
replace type_employment = 2 if household_type == 5 & sector == 1  // Casual labor in rural areas (sector 1)

destring social_security_benefits type_of_contract, replace 

drop if type_of_contract == .  // Drop missing values in 'type_of_contract'

****Generating weights as instructed in the PLFS read file*************
gen weights = mlts/100 if nss == nsc  // Create a variable 'weights'which is 'mlts'/ 100 when 'nss' is equal to 'nsc'
replace weights = mlts/200 if weights == .  // Weight= 'mlts' / 200 if 'nss' is not equal to 'nsc


/*
I am defining contract labourers and permanent labourers as follows.

Contract Labourer: 
Any workers falling under the following categories are considered informal workers in the formal sector
            1.1 Employed with no writtenb with any level of social security
			1.2 Employed on contracts for less than one year with any level of social security
			1.3 Employed on contracts between 2 and 3 years with no social security benefits
			1.4 Any contract with no social security benefits ****
			
Permanent Labourer:
2.1 Non contract workers are permanent.

*/

drop if social_security_benefits==9 //drop if ss_benefits is unknown

/*generate new variable to define vulnerable and secure
Vulnerable = 1 --> Vulnerable
Vulnerable = 0 --> Secure
*/

*using the definition above (numbers in bracket refer to the number in definition)*
gen vulnerable=0 if social_security_benefits==8 // Vulnerable (1.3 and 1.4)
replace vulnerable=0 if type_of_contract==1 // Vulnerable (1.1)
replace vulnerable=0 if type_of_contract==2  // Vulnerable (1.2)
replace vulnerable=1 if vulnerable==. // Secure (2.1)

********************************************************************************************************************************************************
****************************************************Part 2: Preparing the Variables*********************************************************************
********************************************************************************************************************************************************


destring day7_act1_hrs day7_act1_wage day6_act1_hrs day6_act1_wage day5_act1_hrs day5_act1_wage day4_act1_hrs day4_act1_wage day3_act1_hrs day3_act1_wage day2_act1_hrs day2_act1_wage day1_act1_hrs day1_act1_wage, replace // Destring daily wages

local code 1 2 3 4 5 6 7  // Define a local macro 'code' for the days (1 to 7)

//Loop over each day
foreach x of local code {  
    gen day`x' = day`x'_act1_wage / day`x'_act1_hrs  // Calculating the wage per hour for each day (wage/hour)
} 

gen hourly_wage = (day1 + day2 + day3 + day4 + day5 + day6 + day7) / 7  // Calculating the average hourly wage for the week (average across all days)
gen hours = day7_act1_hrs + day6_act1_hrs + day5_act1_hrs + day4_act1_hrs + day3_act1_hrs + day2_act1_hrs + day1_act1_hrs  // Total hours worked in the week (sum of daily hours)
gen monthly_wage = hours * hourly_wage * 4  // Extrapolating weekly earnings to monthly earnings for casual workers

destring earnings_for_wage_activity, replace  
gen wage_earnings_total = monthly_wage + earnings_for_wage_activity  // Calculating total wage earnings from both casual and wage-earning activities

// Extracting Industry codes
gen nic_2digit = substr(nic_code, 1, 2)  // Extracting 2-digit industry code from 'nic_code'
gen nic_3digit = substr(nic_code, 1, 3)  // 3-digit industry code from 'nic_code'
gen nic_4digit = substr(nic_code, 1, 4)  // 4-digit industry code from 'nic_code'
gen state_dist = state_code + district_code  // Creating a new variable by combining state and district codes

set matsize 10000  // Increase matrix size
destring wage_earnings_total sex vulnerable nic_2digit no_of_workers vocational_training workplace_location social_group religion household_type household_size enterprise_type occupation_code marital_status education age sector state_dist, replace  

gen age_squared = age * age  // Generating a new variable age squared (proxy for experience)
gen ln_wage = ln(wage_earnings_total)  // log transformation to 'wage_earnings_total' for a more normalized wage distribution

********************************************************************************************************************************************************
************************************************Part 3: Basic Regressions*******************************************************************************
********************************************************************************************************************************************************


***************Simple OLS**********************
cd "D:\Desktop\Thesis"  // Setting the working directory

**Regressing wages on vulnerability with covariates (clustered standard error at district level)**

reg wage_earnings_total i.vulnerable age household_size i.social_group i.religion i.marital_status i.education i.no_of_workers i.vocational_training /// 
i.workplace_location age_squared i.sex i.enterprise_type i.occupation_code /// 
i.nic_2digit i.sector i.state_dist [pw=weights], cluster(state_dist)  // Regress total wage earnings on vulnerability, including other covariates
scalar coef_first = _b[1.vulnerable]  // Store the coefficient for the variable '1.vulnerable' (the main coefficient of interest)
outreg2 using "Reg1.tex", replace tex keep(1.vulnerable) label  // Export the regression results, keeping only '1.vulnerable' and formatting the output as LaTeX

**Regressing log transformed wages on vulnerability with covariates (clustered standard error at district level)**

reg ln_wage i.vulnerable age household_size i.social_group i.religion i.marital_status i.education i.vocational_training age_squared i.sex /// 
i.sector [pw=weights], cluster(state_dist)  // Regress log-transformed wages on vulnerability with covariates
estimates store Model1  // Store the results of this regression as 'Model1'

reg ln_wage i.vulnerable age household_size i.social_group i.religion i.marital_status i.education i.vocational_training age_squared i.sex /// 
i.sector i.no_of_workers i.workplace_location i.enterprise_type /// 
i.occupation_code i.nic_2digit i.state_dist [pw=weights], cluster(state_dist)  // Regress log-transformed wages with additional covariates and clustering at the district level
estimates store Model2  // Store the results of this regression as 'Model2'

* Exporting the main independent variable (i.vulnerable) coefficients *
estout Model1 Model2 using "Reg2.tex", replace tex keep(1.vulnerable) /// 
label varlabels("1.vulnerable" "Vulnerable Coefficient") /// 
collabels(Regression1 Regression2)  // Export the coefficients of '1.vulnerable' from both models into a LaTeX table

********************************************************************************************************************************************************
**************************************************Part 4: Matching methods******************************************************************************
********************************************************************************************************************************************************

/* I use three different methods of matching

1. Propensity Score matching (both logit and probit) (only exporting select few results to be reported)
   - KNN Matching
   - Caliper Matching
   - Kernel Matching
2. Coarsened Exact Matching 
3. Entropy Balancing

*/

**************Propensity Score KNN Matching (Logit and Probit models):**************

*KNN matching with logit model (neighbor count=3, caliper=0.001, common support, trimming=0.1):

****Logit Model
psmatch2 vulnerable age household_size i.social_group i.religion i.marital_status i.education i.vocational_training age_squared i.sex ///
i.sector i.no_of_workers i.workplace_location i.enterprise_type i.occupation_code i.nic_2digit i.state_dist, ///
out(ln_wage) neighbor(3) caliper(0.001) common trim(0.1) odds index logit ties warnings
display "The p-value is " 2*ttail(e(df_r), abs(r(att)/r(seatt))) // Display p-value for the treatment effect

estimates store Model1 // Store the results

****Probit Model
psmatch2 vulnerable age household_size i.social_group i.religion i.marital_status i.education i.vocational_training age_squared i.sex ///
i.sector i.no_of_workers i.workplace_location i.enterprise_type i.occupation_code i.nic_2digit i.state_dist, ///
out(ln_wage) neighbor(3) caliper(0.001) common trim(0.1) odds index ties warnings
display "The p-value is " 2*ttail(e(df_r), abs(r(att)/r(seatt))) // Display p-value for the treatment effect

**************Propensity Score Caliper Matching (Logit and Probit models):**************

*Caliper matching with logit model (caliper=0.001, common support):

****Logit Model
psmatch2 vulnerable i.nic_2digit i.social_group i.religion household_size age_squared i.sex i.enterprise_type i.occupation_code i.marital_status i.education age ///
i.sector i.state_dist, out(ln_wage) caliper(0.001) common logit
display "The p-value is " 2*ttail(e(df_r), abs(r(att)/r(seatt))) // Display p-value for the treatment effect
estimates store Model2 // Store the results

****Probit Model
psmatch2 vulnerable i.nic_2digit i.social_group i.religion household_size age_squared i.sex i.enterprise_type i.occupation_code i.marital_status i.education age ///
i.sector i.state_dist, out(ln_wage) caliper(0.001) common 
display "The p-value is " 2*ttail(e(df_r), abs(r(att)/r(seatt))) // Display p-value for the treatment effect


**************Propensity Score Kernel Matching (Logit and Probit models with different kernel types):**************

*Kernel Matching with Epanechnikov distribution and logit model (bandwidth=0.05):

****Logit Model
psmatch2 vulnerable age household_size i.social_group i.religion i.marital_status i.education i.vocational_training age_squared i.sex ///
i.sector i.no_of_workers i.workplace_location i.enterprise_type i.occupation_code i.nic_2digit i.state_dist, ///
out(ln_wage) kernel kerneltype(epan) bwidth(0.05) common trim(0.1) odds index logit
display "The p-value is " 2*ttail(e(df_r), abs(r(att)/r(seatt)))

****Probit Model
psmatch2 vulnerable age household_size i.social_group i.religion i.marital_status i.education i.vocational_training age_squared i.sex ///
i.sector i.no_of_workers i.workplace_location i.enterprise_type i.occupation_code i.nic_2digit i.state_dist, ///
out(ln_wage) kernel kerneltype(epan) bwidth(0.05) common trim(0.1) odds index
display "The p-value is " 2*ttail(e(df_r), abs(r(att)/r(seatt))) // Display p-value for the treatment effect
 
*Kernel Matching with Normal distribution and logit model (bandwidth=0.05):

****Logit Model
psmatch2 vulnerable age household_size i.social_group i.religion i.marital_status i.education i.vocational_training age_squared i.sex ///
i.sector i.no_of_workers i.workplace_location i.enterprise_type i.occupation_code i.nic_2digit i.state_dist, ///
out(ln_wage) kernel kerneltype(normal) bwidth(0.05) common trim(0.1) odds index logit
display "The p-value is " 2*ttail(e(df_r), abs(r(att)/r(seatt))) // Display p-value for the treatment effect
estimates store Model3 // Store the results

****Probit Model
psmatch2 vulnerable age household_size i.social_group i.religion i.marital_status i.education i.vocational_training age_squared i.sex ///
i.sector i.no_of_workers i.workplace_location i.enterprise_type i.occupation_code i.nic_2digit i.state_dist, ///
out(ln_wage) kernel kerneltype(normal) bwidth(0.05) common trim(0.1) odds index
display "The p-value is " 2*ttail(e(df_r), abs(r(att)/r(seatt)))

estout Model1 Model2 Model3 using "PSmatch_logit.tex", replace tex keep(1.vulnerable) ///
label varlabels("1.vulnerable" "Vulnerable Coefficient") ///
collabels(KNN_mathcing Caliper_matching Kernel_matching) // Export the results for KNN, Caliper, and Kernel matching into a LaTeX file (only logit)


***************Coarsened Exact Matching (CEM):**************

*Obtain unique values for `state_code` and `nic_2digit` as this is used for coarsening
levelsof state_code, local(unique_state_code)
local num_unique : word count `unique_state_code' // Count the number of unique state codes and store it in `num_unique`
display "Number of unique observations in state_dist: `num_unique'"  // Display the number of unique state codes

levelsof nic_2digit, local(unique_nic)
local num_unique : word count `unique_nic' // Count the number of unique NIC codes and store it in `num_unique`
display "Number of unique observations in nic_2digit: `num_unique'" // Display the number of unique NIC codes

*Coarsened Exact Matching:
cem age(#7) education(#13) sex(#3) social_group(#4) religion(#9) state_code(#37) ///
nic_2digit(#87) sector(#2) marital_status(#4) household_type(#3) enterprise_type (#12), treatment(vulnerable) // The numbers are detrmined using  number of unique obsrvations or based on desired number of bins

*Using the matched weights (CEM) for the regression:
reg ln_wage vulnerable household_size age_squared i.no_of_workers i.vocational_training i.workplace_location i.occupation_code i.state_dist [iw=cem_weights], cluster(state_dist) // Using CEM weights, SE clustered at the district level

outreg2 using "CEM_results.tex", cells(b(star fmt(3)) se(par)) label starlevels(* 0.10 ** 0.05 *** 0.01) title("Regression Results with CEM Weights") replace //Export the regression results to a LaTeX file

**************Entropy Balancing:**************

*Entropy balancing to balance covariates:
xi: ebalance vulnerable age household_size i.social_group i.religion i.marital_status i.education i.no_of_workers i.vocational_training ///
i.workplace_location age_squared i.sex i.enterprise_type i.occupation_code ///
i.nic_2digit i.sector i.state_code, gen(eweight) maxiter(25) ///Creates eweight which contains the weights as per entropy balancing

*To check the balance of weights for treatment and control groups:
total eweight if vulnerable==1 // Treatment group
total eweight if vulnerable==0 // Control group

*Regression using entropy weights:
reg ln_wage vulnerable i.state_dist [aw=eweight], cluster(state_dist)

outreg2 using results.txt, replace ctitle("Regression Results with Entropy Weights") ///
b(star fmt(3)) se(par) label starlevels(* 0.10 ** 0.05 *** 0.01)  //Exporting entropy balanced coeffecient

********************************************************************************************************************************************************
************************************************************Part 5: Decomposition***********************************************************************
********************************************************************************************************************************************************

********Oaxaca-blinder decomposition**************

***********All fixed effects************
xi: oaxaca ln_wage age household_size i.social_group i.religion i.marital_status i.education i.no_of_workers i.vocational_training ///
i.workplace_location age_squared i.sex i.enterprise_type i.occupation_code ///
i.nic_2digit i.sector i.state_dist, by(vulnerable) swap relax cluster(state_dist) [pw=weights]  //Oaxaca decomposition, including all fixed effects; cluster standard errors by district and apply weights

/* The `by(vulnerability)` option specifies that the decomposition will be done based on the vulnerability status (vulnerable vs secure).
Options used:
   - `swap`: allows for the decomposition of both the explained and unexplained portions of the wage gap.
   -  clusters standard errors by state-level regions.
*/

*I run the following decompositions to check if the respective fixed effects have an impact on the results of the decomposition

***********No district Fixed Effects***********
xi: oaxaca ln_wage age household_size i.social_group i.religion i.marital_status i.education i.no_of_workers i.vocational_training i.workplace_location age_squared i.sex ///
i.enterprise_type i.occupation_code i.nic_2digit i.sector, by(vulnerable) swap relax cluster(state_dist) [pw=weights]

***********No Industry Fixed Effects****************
xi: oaxaca ln_wage age household_size i.social_group i.religion i.marital_status i.education i.no_of_workers i.vocational_training ///
i.workplace_location age_squared i.sex i.enterprise_type i.occupation_code i.sector i.state_dist, by(vulnerable) swap relax cluster(state_dist) [pw=weights]

*******No District and Industry Fixed Effects**********
xi: oaxaca ln_wage age household_size i.social_group i.religion  i.marital_status i.education i.no_of_workers i.vocational_training ///
i.workplace_location age_squared i.sex i.enterprise_type i.occupation_code i.sector, by(vulnerable) swap relax cluster(state_dist) [pw=weights]


****************Regrouping Industry, work place, state code****************
****Since there are too many classifications for some of the factor variables, I recategorize them into fewer categories to improve effeciency

****Industry*********
*Recoding Industry into fewer categories

gen nic= "Agriculture" if nic_2digit==1| nic_2digit==2| nic_2digit==3  // Group NIC codes 1, 2, and 3 as 'Agriculture'
forvalues x = 5/9 { 
    replace nic= "Mining and quarrying" if nic_2digit==`x'  // Group NIC codes 5-9 as 'Mining and quarrying'
}

local code 10 11 12 13 14 15 16 17 18 22 31 32 33 
foreach x of local code { 
    replace nic= "Manufacturing products" if nic_2digit==`x'  // Group NIC codes 10-18, 22, 31-33 as 'Manufacturing products'
}

local code 19 20 21 23 24 25 26 27 28 29 30
foreach x of local code { 
    replace nic= "Manufacturing metals, chemicals, electronics, vehicles" if nic_2digit==`x'  // Group NIC codes 19-30 as 'Manufacturing metals, chemicals, electronics, vehicles'
}

forvalues x = 35/39 { 
    replace nic= "electricity and water" if nic_2digit==`x'  // Group NIC codes 35-39 as 'electricity and water'
}

forvalues x = 41/43 { 
    replace nic= "Construction" if nic_2digit==`x'  // Group NIC codes 41-43 as 'Construction'
}

forvalues x = 45/47 { 
    replace nic= "Trade" if nic_2digit==`x'  // Group NIC codes 45-47 as 'Trade'
}

forvalues x = 49/53 { 
    replace nic= "Transport and storage" if nic_2digit==`x'  // Group NIC codes 49-53 as 'Transport and storage'
}

forvalues x =55/99 { 
    replace nic= "Service sector" if nic_2digit==`x'  // Group NIC codes 55-99 as 'Service sector'
}


**********Workplace location**************
*Recoding workplace locations into fewer categories
gen location = "own dwelling" if workplace_location == 10 | workplace_location == 11 | workplace_location == 12 | workplace_location == 13 | workplace_location == 14  // Group several location codes as 'own dwelling'

forvalues x=20/24 { 
    replace location = "own dwelling" if workplace_location == `x'  // Group more location codes as 'own dwelling'
}

local code 14 15 24 25 
foreach x of local code { 
    replace location = "Employer's dwelling" if workplace_location == `x'  // Group location codes 14, 15, 24, 25 as 'Employer's dwelling'
}

replace location = "Street" if workplace_location ==17 | workplace_location ==27  // Group codes 17 and 27 as 'Street'
replace location = "Construction site" if workplace_location ==18 | workplace_location ==28  // Group codes 18 and 28 as 'Construction site'
replace location = "Others" if missing(location)  // For remaining missing values, categorize as 'Others'

********* Enterprise type ****************

*Recoding enterprise types into broader categories
gen Enterprise= "Proprietary" if enterprise_type==01 | enterprise_type==02  // Group enterprise types 01 and 02 as 'Proprietary'
replace Enterprise= "Partnership" if enterprise_type==03 | enterprise_type==04  // Group enterprise types 03 and 04 as 'Partnership'
replace Enterprise= "Public sector, coops or govt" if enterprise_type==05 | enterprise_type==06 | enterprise_type==10  // Group enterprise types 05, 06, 10 as 'Public sector, coops or govt'
replace Enterprise= "Private, autonomous, NP" if enterprise_type==07 | enterprise_type==08 | enterprise_type==11  // Group enterprise types 07, 08, 11 as 'Private, autonomous, NP'
replace Enterprise= "Other" if missing(Enterprise)  // For missing values, categorize as 'Other'

***************** Occupation code ***********

*Recoding occupation codes into a new variable for broader categories
gen occupation_1digit_code = substr(string(occupation_code), 1, 1)  // Create a new variable 'occupation_1digit_code' with the first digit of the occupation code

***** Education ********

*Recoding education levels into broader categories
gen edu="no schooling" if education==01 | education==02 | education==03 | education==04  // Group education codes 01-04 as 'no schooling'
replace edu= "primary" if education==05 | education==06  // Group education codes 05-06 as 'primary'
replace edu= "10th or below" if education==07 | education==08  // Group education codes 07-08 as '10th or below'
replace edu= "higher secondary" if education==10  // Group education code 10 as 'higher secondary'
replace edu="diploma" if education==11  // Group education code 11 as 'diploma'
replace edu="higher education" if missing(education)  // For missing values, categorize as 'higher education'

***** Oaxaca with new classifications ******

xi: oaxaca ln_wage age household_size i.social_group i.religion /// 
i.marital_status i.edu i.no_of_workers i.vocational_training /// 
i.location age_squared i.sex i.Enterprise i.occupation_1digit_code /// 
i.nic i.sector i.state_code, by(vulnerable) swap relax cluster(state_dist) [pw=weights]  //Oaxaca decomposition with the newly recategorized variables, same options

********************************************************************************************************************************************************
*******************************************Part 6: Multinomial Logit Regression*************************************************************************
********************************************************************************************************************************************************

use "D:\Desktop\Thesis\New topic\Appended Data.dta", clear  

gen yr = substr(year, 1, 4)  // Generate year variable (extracts first 4 characters of 'year' string)
gen nic_2digit = substr(nic_code, 1, 2)  // Generate 2-digit NIC code
gen state_dist = state_code + district_code  // Create a unique state and district code by summing 'state_code' and 'district_code'

set matsize 10000  // Set maximum matrix size for larger calculations

destring yr wage_earnings_total sex vulnerable nic_2digit occupation_code no_of_workers vocational_training workplace_location social_group religion household_type household_size enterprise_type occupation_code marital_status education age sector state_dist, replace  // Convert string variables to numeric for regression analysis

gen age_squared = age * age  // Create a new 'age_squared' variable as a proxy for experience (age squared)

reg vulnerable i.yr age household_size i.social_group i.religion i.marital_status i.education i.workplace_location age_squared i.sex i.occupation_code /// 
i.nic_2digit i.sector i.state_dist , cluster(state_dist)  // Logistic regression for the 'vulnerable' outcome variable with clustered standard errors by 'state_dist'

mlogit vulnerable i.yr i.social_group i.religion i.marital_status i.education i.workplace_location i.sex i.occupation_code /// 
i.nic_2digit i.sector i.state_dist [pw=weights], basecategory(1) cluster(state_dist)  // Multinomial logistic regression with 'vulnerable' as the dependent variable, clustering error by 'state_dist', Base category set to secure

drop if yr == 2017 | yr == 2018  // Drop observations for the years 2017 and 2018

logit vulnerable i.yr i.social_group i.religion i.marital_status i.education i.workplace_location i.sex i.occupation_code /// 
i.nic_2digit i.sector i.state_dist [pw=weights], cluster(state_dist)  // Logistic regression again after dropping years 2017 and 2018, clustering error by 'state_dist'
		
import excel "D:\Desktop\Thesis\New topic\Estimates.xlsx", sheet("Years and vulnerable contract") firstrow clear  // Import Excel data from the 'Estimates' sheet for further analysis

twoway (line Coef Year)(rcap F Interval Year), xtitle("Year") ytitle("Coefficient") ///  
graphregion(color(white)) ylabel(#10)  // Plot the coefficient estimates over time with confidence intervals using a line plot

graph export "D:\Desktop\Thesis\New topic\Graphs\Mobility.png", as(png) replace  // Exporting the graph as a PNG image

