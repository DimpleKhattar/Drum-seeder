/******************************************************************************
Author : Dimple Khattar
Purpose: Creating a list of respondents who will be backchecked 
Date: 18-06-2023
********************************************************************************
Modified by	   : 
Last Edit Date : 
*******************************************************************************/

clear all 
set more off

/*******************************************************************************
	SECTION : Setting the directory and path			
    Notes: */ 
*******************************************************************************/ 
global present_date "20230811"
 
global identity "C:/Users//`c(username)'"
global clean_dta "${identity}/Dropbox/Drum Seeder Project/01_data_and_codes/03_cleaning/output/05_prep"
global backcheck "${identity}/Dropbox/Drum Seeder Project/01_data_and_codes/06_backcheck/output"
use "${clean_dta}/clean_sarpanch.dta "

*keep if survey_date>=23187 

keep if survey_status==1 

keep if district=="Jagitial" | district=="Karimnagar" | district=="Peddapalli"

gen total_complete=1 if survey_status==1
replace total_complete=0 if total_complete==.
egen total_done_north= total(total_complete)

// Calculating 20% observations
gen calc_do = (20/100)*total_done_north

//Setting seed so that the output remains same if the code is run by otehr user
set seed 20210310 

sort surveyor_id
//Running the random code
gen random= runiform()
sort random
generate count_n=_n
drop if count_n>calc_do

// Keeping only the relevant variables 
keep district mandal panchayat survey_date a5_sarpanch a6_relatn_sarpn 
export excel using "${backcheck}//${present_date}/randomised_list_North.xls",firstrow(variables) replace
keep district mandal panchayat 

save "${backcheck}/randomised_gp_north.dta", replace

use "${clean_dta}/clean_labour_map.dta"

merge m:1 panchayat using "${backcheck}/randomised_gp_north.dta"

keep if _merge==3

*Keeping only the relevant variables
keep district mandal panchayat job_card_no survey_date prim_mobile prim_mobile_2 prim_mobile_3 alt_mobile_1 alt_mobile_2 alt_mobile_3 alt_mobile_4 alt_mobile_21

*Saving an excel file
export excel using "${backcheck}//${present_date}/randomised_list_labour_North.xls",firstrow(variables) replace
