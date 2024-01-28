/******************************************************************************
Author : Dimple Khattar
Purpose: To clean the dataset: 
	1. Deidentify dataset
	2. Dropping duplicates
	2. Fixing errors or errors done by enum 
	
Date: 11-10-2023
*******************************************************************************/
clear all 
set more off

/*******************************************************************************
	SECTION : Setting the directory and path			
    Notes: */ 
*******************************************************************************/ 
global veracrypt "A:"
global identity "C:\Users\\`c(username)'"
global append_dta "${identity}\Dropbox\Drum Seeder Project\01_data_and_codes\03_cleaning\output\03_append" 
global deidentify_dta "${identity}\Dropbox\Drum Seeder Project\01_data_and_codes\03_cleaning\output\01_deidentify"
global dup_error_fix_dta "${identity}\Dropbox\Drum Seeder Project\01_data_and_codes\03_cleaning\output\04_duplicates_error_fix"
global raw_dta "${veracrypt}\02_raw_dta"
global clean_dta "${identity}\Dropbox\Drum Seeder Project\01_data_and_codes\03_cleaning\output\05_prep"
local aeo_input "${veracrypt}\aeosarpanchsamp.dta" 
local cleaning_input "${identity}\Dropbox\Drum Seeder Project\01_data_and_codes\03_cleaning\input"

use "${raw_dta}\\${present_date}\Farmer_Survey_Field.dta", clear

/*******************************************************************************
	SECTION : Deidentify dataset 
*******************************************************************************/ 
drop caseid a4_farmer_name mobile_no

/*******************************************************************************
	SECTION : Dropping duplicates	
    Notes: 
	1. We will use more than 2 identifiers to drop a data point from the dataset. 
	Key should definitely be one of the variable. Another can be unique id, survey 
	date,survey status, surveyor id 

	2. While dropping a data point, ensure to write the detailed reason for 
	dropping the data point. 
*******************************************************************************/ 

//This file stores information about duplicates 
use "${deidentify_dta}\deidentify_farmer.dta", clear

//Merging the file with main datset
merge 1:1 key using "`cleaning_input'\farmer\duplicates_farmer_20231010.dta", keepusing (Keep Comment updated_value) force 

keep if _merge==1 | (_merge==3 & Keep==1) | (_merge==3 & Keep==2) 

/*******************************************************************************
	SECTION : Fixing errors
    Notes: 
	1. We will use more than 2 identifiers to change a data point from the dataset. 
	Key should definitely be one of the variable. Another can be unique id, survey 
	date,survey status, surveyor id 

	2. While dropping a data point, ensure to write the detailed reason for 
	dropping the data point. 
*******************************************************************************/ 
replace survey_date=23273 if survey_date==22543
replace unique_id= updated_value if key=="uuid:4110d616-37af-4775-b978-76abb7771bed"

/*******************************************************************************
	SECTION : Prepping variables
*******************************************************************************/ 
destring surveyor_id, replace

*Assiging a new unique_id
duplicates tag unique_id, gen(dup)
bysort unique_id: gen num= _n

gen new_unique_id= unique_id if dup==0
replace new_unique_id= unique_id + "_1" if dup==1 & num==1
replace new_unique_id= unique_id + "_2" if dup==1 & num==2

rename unique_id old_unique_id
rename new_unique_id unique_id

*Dropping variables
drop num dup

*merging it with AEO input file 
destring panchayatid, replace
merge m:1 panchayatid using "`aeo_input'", keepusing (treat_group) gen(merge_treat)

keep if merge_treat==3
drop merge_treat

/*******************************************************************************
	SECTION : Saving the outputs			
    Notes: */ 
*******************************************************************************/ 
save "${clean_dta}\clean_farmer.dta", replace 

/****************************End-of-do-file*************************************
