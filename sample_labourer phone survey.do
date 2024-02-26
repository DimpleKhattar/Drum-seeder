/******************************************************************************
Author : Dimple Khattar
Purpose: Sample for labourer phone survey 
Date: 14-02-2024
*******************************************************************************/
clear all
set more off

/*******************************************************************************
	SECTION : Setting the directory and path			
    Notes: */ 
*******************************************************************************/ 
global identity "C:/Users//`c(username)'/Dropbox"
local veracrypt "F:" //Location:C:\Users\Dimple Khattar\Dropbox\Drum Seeder Project\01_data_and_codes\08_others\prefill\output\Phone survey 
local vercarypt_1 "B:" //location: C:\Users\Dimple Khattar\Dropbox\DrumSeeder raw data\2024\sample

*Saving the file as a .dta file
import delimited "`vercarypt_1'\04 Labourer Phone Survey\labour v17\prefill (7).csv", clear 
save "`vercarypt_1'\04 Labourer Phone Survey\labour v17\prefill_labourer_phone.dta", replace 

* this data was a mess and the sample needed on an urgent basis. 
use "`veracrypt'/02_raw_dta/20230810/DRUM_SEEDER_FARMER_LABOURER_PHONE_SURVEY_V8.dta", clear
append using "`veracrypt'/02_raw_dta/20230810/DRUM_SEEDER_FARMER_LABOURER_PHONE_SURVEY_V9.dta", force
append using "`veracrypt'/02_raw_dta/20230810/DRUM_SEEDER_FARMER_LABOURER_PHONE_SURVEY_V10.dta", force
append using "`veracrypt'/02_raw_dta/20230904/DRUM_SEEDER_FARMER_LABOURER_PHONE_SURVEY_V14.dta", force
append using "`veracrypt'/02_raw_dta/20230910/DRUM_SEEDER_FARMER_LABOURER_PHONE_SURVEY_V15_WIDE.dta", force
append using "`veracrypt'/02_raw_dta/20230916/DRUM_SEEDER_FARMER_LABOURER_PHONE_SURVEY_V16.dta", force
append using "`veracrypt'/02_raw_dta/20230916/DRUM_SEEDER_FARMER_LABOURER_PHONE_SURVEY_V17.dta", force

//Keeping only the completed surveys where we had consent 
gen complete=1 if !mi(nrega) & mi(c5_consent_reject_reason)
keep if c1_available_for_study==1 & complete==1

//Keeping only unique job card ids
bysort a4_labr_job_card_num: gen dup=_n
keep if dup==1

rename a4_labr_job_card_num job_card_no

//Merging with prev round prefill 
merge 1:1 job_card_no using "`vercarypt_1'/04 Labourer Phone Survey/labour v17/prefill_labourer_phone.dta", gen(merge_2) force 
keep if merge_2==3

*merge 1:1 job_card_no  using "C:/Users/Dimple Khattar/Dropbox/Drum Seeder Project/01_data_and_codes/03_cleaning/output/05_prep/clean_farmer_labourer.dta", gen(merge_3) force

//keeping prim number as the one which we were able to connect the last time 
gen prim_number= enter_alter_num 
replace prim_number= calc_resp_ph_num if mi(prim_number) & mi(enter_alter_num)
replace prim_number= a6_mobile_number if mi(prim_number) & mi(enter_alter_num) & mi(calc_resp_ph_num)

rename prim_mobile alt_mobile_0 
rename prim_number prim_mobile
replace alt_mobile_0 = "" if alt_mobile_0 ==prim_mobile

*keeping only relevant variables
keep job_card_no district mandal	panchayat father_name labourer_name	kind_phone	prim_mobile	alt_mobile_0 alt_mobile_1 alt_mobile_2 alt_mobile_3	alt_mobile_4	alt_mobile_5 alt_mobile_6 alt_mobile_7 alt_mobile_8
order job_card_no district mandal	panchayat father_name labourer_name	kind_phone	prim_mobile	alt_mobile_0 alt_mobile_1 alt_mobile_2 alt_mobile_3	alt_mobile_4	alt_mobile_5 alt_mobile_6 alt_mobile_7 alt_mobile_8

*saving file
export delimited using "A:/prefill_labourer_phone survey.csv", replace

