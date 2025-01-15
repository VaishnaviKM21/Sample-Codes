# Sample Codes
This repository contains a collection of sample codes written by **Vaishnavi Krishna Mohan**. It includes **STATA** and **R** scripts from different research projects. Below is a brief overview of the contents:

## Files Structure
- **STATA Folder**: Contains four sample STATA `.do` files, which are unrelated to each other.
- **R Folder**: Contains two rendered R markdown files, one of which is a continuation of the STATA do-file "RCT Randomisation."

## STATA Codes

1. **Thesis Model Code**  
   This code is part of my thesis on classifying vulnerable workers in India and studying the wage gap, mobility, and sorting into labor markets. Using cleaned **Periodic Labour Force Survey (PLFS)** data, the code implements various methods, including **matching techniques**, **Oaxaca-Blinder decomposition**, and **multinomial logit models**.

2. **Exploratory Analysis**  
   This code performs an exploratory analysis of female labor force participation trends in Madhya Pradesh. I demonstrate skills such as data preparation, graphical analysis, and implementing Fixed effects models.

3. **RCT Randomisation**  
   This do-file implements randomization techniques for a **Cluster-Randomized Controlled Trial (RCT)** examining interventions to improve latrine usage in rural India, focusing on religious stigma and health awareness using **MIS** and **NFHS** data.

4. **Time Series Code – VAR Model**  
   This code models the relationship between the **Index of Industrial Production (IIP)** and the **unemployment rate** using a **Vector Autoregression (VAR)** model, analyzing both urban and rural unemployment and finding bidirectional effects and greater volatility in rural unemployment.

## R Files

**Propensity Score Matching (PSM)**  
   This R script performs **Propensity Score Matching** using data on **firms in Myanmar** to examine whether exporting firms in low-income countries have worse labor conditions (pay, hours, safety). The analysis was part of a Stats class and is inspired by the paper: Tanaka, Mari (2020), "Exporting Sweatshops? Evidence from Myanmar," *Review of Economics and Statistics*.

**Mahalanobis Distance**  
   This R script calculates the **Mahalanobis Distance** to assess homogeneity between treatment and control groups after randomization. This ensures comparability for further analysis, following the RCT process described in the STATA do-file.
