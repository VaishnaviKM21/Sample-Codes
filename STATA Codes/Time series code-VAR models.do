*********************************************************************************************************************
**********************************Manufacturing Index and Unemployment***********************************************
*********************************************************************************************************************

use "D:\Desktop\IIP and Uer Manu.dta", clear   // Load the dataset and clear previous data
set more off   // Turn off the "more" option to prevent the output from pausing
tsset n   // Declare the time series variable 'n' for time series analysis

****Stationarity tests (p value to be less than 0.05)
dfuller IIP   // Augmented Dickey-Fuller test for stationarity on the 'Industrial index' variable
dfuller manufacturing  //manufacturing index
dfuller uer   //Unemployment rate
dfuller urban_uer   //Urban unemployment rate
dfuller rural_uer   //Rural unemployment rate

tsline IIP uer, yline(0)   // Plotting the time series for 'IIP' and 'uer' with a horizontal line at 0
tsline manufacturing urban_uer rural_uer, yline(0)   // Plot 'manufacturing', 'urban_uer', and 'rural_uer' time series 
tsline capital_goods urban_uer rural_uer, yline(0)   
tsline capital_goods manufacturing IIP   

***There are 5 types of goods by usage. However, for this paper, we will only try to compare infrastructure and intermediate as these are the two most labor-intensive sectors

varsoc   // Selecting optimal lag length for the VAR model using AIC/BIC criteria
var IIP uer, lag(1/2)   // Estimating a VAR model for 'IIP' and 'uer' with lags 1 and 2
varstable   // Check the stability condition of the VAR model
vargranger   // Perform the Granger causality test for the VAR model

**Basic VAR model for 'IIP' and 'urban'
varbasic IIP urban   
varstable   
vargranger   

**Basic VAR model for 'IIP' and 'rural'
varbasic IIP rural   
varstable   
vargranger   

**Basic VAR model for 'manufacturing' and 'rural'
varbasic manufacturing rural   
varstable  
vargranger 
  
**Fitting a VAR model for 'manufacturing' with lags 1 and 2 
var manufacturing, lag(1/2)   
varstable   
vargranger 
  
**Basic VAR model for 'manufacturing', 'urban', and 'rural' 
varbasic manufacturing urban rural   
varstable   
vargranger   

***Because AIC is at lag 2 and BIC is at lag 0   // AIC suggests lag 2, BIC suggests lag 0 as the optimal lags

varstable   // Check the stability condition for the VAR model
**it gives us the eigenvalues. Stability conditions. If it's less than one, then the system is stable

**Calculating the residuals from the VAR model
predict error, resid   

tsline error, yline(0)   // Plot the residuals of the model 
***It is white noise   

**Granger causality
vargranger   
***We look at the p-value for Granger causality

test([rain]: foodpc)   // Test whether investment Granger causes income (foodpc variable)

****To check normality of disturbances. 
**The null hypothesis is that errors are normally distributed
varnorm  

***Impulse response function
irf create IRF, set(IRF, replace)   
irf graph oirf, set(IRF) irf(IRF) impulse(manufacturing) response(urban_uer rural_uer) yline(0)   // Graph OIRF with shock on 'manufacturing' and response of 'urban_uer' and 'rural_uer'
irf graph oirf, set(IRF) irf(IRF) impulse(area) response(foodpc) yline(0)   // Graph the OIRF with shock on 'area' and response of 'foodpc'

***OIRF is orthogonal impulse response function. The impulse is where the shock originates. Here, the shock is on 'dln_inv' and 'dln_consump'
*** Response shows the graph of how the system reacts to the shock

irf graph oirf   // Display OIRF for all variables in the system

***Forecast
fcast compute forecast, step(10)   // Compute forecasts for the next 10 periods
***Forecast is the name of the variable, and 'step(10)' defines how many periods ahead to forecast

***Time series graphs
tsline d2gdp_pc forecastd2gdp_pc, yline(0)   
tsline d2life_exp forecastd2life_exp, yline(0)   
tsline dln_consump forecastdln_consump, yline(0)   
tsline gdp_pc forecastgdp_pc, yline(0)   // Plot actual and forecasted 'gdp_pc'
tsline life_exp forecastlife_exp, yline(0)   // Plot actual and forecasted 'life_exp'

varbasic dln_inc dln_inv dln_consump   // Fit a basic VAR model for 'dln_inc', 'dln_inv', and 'dln_consump'
