/******************************************************************************
Author : Dimple Khattar
Purpose: High frequency checks for farmer dataset 	
Date: 25-09-2023
********************************************************************************/

clear all 
set more off

*::::::::::::::::::::::::::::::::::::::::::::::::::::::::

**Install user-written commands 
foreach package in mdesc nmissing veracrypt {
     capture which `package'
     if _rc==111 ssc install `package'
}

	version 12 
	pause on 
	set more off 
	qui cap log c 
*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::

*--------------------------------------------------------
** Mount VeraCrypt container & set directories
*--------------------------------------------------------

	if c(os) == "Windows" {
		local DROPBOX "C:\Users\\`c(username)'\Dropbox"
	}
	else if c(os) == "MacOSX" {
		local DROPBOX "/Users/`c(username)'/Dropbox/"
	}
	
* Current directory 
	cd "`DROPBOX'/Drum Seeder Project/01_data_and_codes/03_cleaning/output/05_prep" 
	local data "clean_farmer.dta" 

* Setting locals for output folders (logs, reports, errors, etc.) 
	local reports "`DROPBOX'/Drum Seeder Project/01_data_and_codes/05_monitoring/output/farmer" 	

	//Using Data
	use "`data'", clear

* Define key variables 
	local unique "unique_id" 			// Unique ID variable										
	local enum "surveyor_id" 			// Enumerator code variable 									

*==========================================================================
************************* Unique ID Checks ********************************
*==========================================================================

*--------------------------------------------------------------------------
** Checking for missing Unique IDs
*--------------------------------------------------------------------------
*The Unique ID cannot be missing. 

mdesc `unique' 
cap assert `r(miss)' == 0 
	if _rc != 0 {
		di "`unique' has `r(miss)' missing values" 
	}

cap export excel `unique' `enum' a4_farmer_name survey_status starttime endtime key using "`reports'/unique_farmer.xlsx" if `unique' == "", firstrow(variables) replace

*--------------------------------------------------------------------------
** Duplicates in unique ID
*--------------------------------------------------------------------------
sort `unique', stable
qui by `unique': gen dup = cond(_N==1,0,_n) 
	count if dup > 0 

export excel `unique' `enum' resp_rel starttime dup survey_status consent p3_comments key using "`reports'/duplicates_farmer.xlsx" if dup > 0 & !missing(`unique'), firstrow(variables) replace
*isid `unique'  // This line should run successfully once all duplicates are fixed

drop dup

*==========================================================================
*Keeping only the obs with consent==1
keep if consent==1
*==========================================================================

*==========================================================================
************************** Date & Time Checks *****************************
*==========================================================================

sort `unique'

** Surveys that don't end on the same day as they started
list `unique' starttime endtime if dofc(starttime) != dofc(endtime), sep(0)
cap export excel surveyor_id unique_id starttime endtime using "`reports'/date_time_farmer.xlsx" if dofc(starttime) !=dofc(endtime), firstrow(variables)  sheet("Sheet 1") replace

** Surveys where end date/time is before start date/time
list `unique' starttime endtime if dofc(starttime) > dofc(endtime), sep(0)
cap export excel using "`reports'/date_time_farmer.xlsx" if dofc(starttime) > dofc(endtime), firstrow(variables) sheet("Sheet 2") replace

list `unique' starttime endtime if Cofc(starttime) > Cofc(endtime) & dofc(starttime) == dofc(endtime), sep(0)
cap export excel using "`reports'/date_time_farmer.xlsx" if Cofc(starttime) > Cofc(endtime) & dofc(starttime) == dofc(endtime), firstrow(variables) sheet("Sheet 3") replace

** Surveys that show starttime earlier than first day of data collection
list `unique' starttime if dofc(starttime) < mdy(9, 05, 2023)
cap export excel using "`reports'/date_time_farmer.xlsx" if dofc(starttime) < mdy(9, 05, 2023), firstrow(variables) sheet("Sheet 4") replace

*==========================================================================
***************************** Distributions *******************************
*==========================================================================

*--------------------------------------------------------------------------
** Missing Values
*--------------------------------------------------------------------------

** Variables with all observations missing  

qui nmissing, min(*)  

putexcel set "`reports'/missing_values.xlsx", sheet("All values missing") replace
local i=2
putexcel A1= ("Variables which have all values missing")
foreach j of varlist `r(varlist)' { 
	quietly{
		putexcel A`i'= ("`j'")
	
	} 
	local i=`i'+1
}

** Missing value percentages for remaining variables
	
	
local w "`r(varlist)'" 	// storing the result of the nmissing command above in w 
qui ds `w', not 
	local x "`r(varlist)'"

qui ds `x', has(type numeric)


putexcel set  "`reports'/missing_values.xlsx", sheet("Missing values percentages_num") modify
putexcel A1=("Displaying missing observations in numeric variables")
putexcel A2=("Variable")
putexcel B2= ("Percentage of missing observations")
putexcel C2= ("Frequency of missing observations")
local i=3
foreach var of varlist `x' { 
	qui mdesc `var', ab(32) 
	if `r(total)' != 0 {
	*di "`var'{col 32}" %10.0f r(percent) %10.0f r(miss) //This line will show output in console too
	quietly{ 
	putexcel A`i'=("`var'")
	putexcel B`i'=matrix(r(percent))
	putexcel C`i'=matrix(r(miss))
	*putexcel D`i'=matrix(r(`total')) // figure it out wit SB 
	
	}
	local i=`i'+1
	}
	
}

** Missing value percentages for remaining variables 
	
local w "`r(varlist)'" 	// storing the result of the nmissing command above in w 
qui ds `w', not 
	local x "`r(varlist)'"

ds `x', has(type numeric)

putexcel set  "`reports'/missing_values.xlsx", sheet("Missing values percentages_num") modify
putexcel A1=("Displaying missing observations in numeric variables")
putexcel A2=("Variable")
putexcel B2= ("Percentage of missing observations")
putexcel C2= ("Frequency of missing observations")
local i=3
foreach var of varlist `x' { 
	qui mdesc `var', ab(32) 
	if `r(total)' != 0 {
	*di "`var'{col 32}" %10.0f r(percent) %10.0f r(miss) //This line will show output in console too
	quietly{ 
	putexcel A`i'=("`var'")
	putexcel B`i'=matrix(r(percent))
	putexcel C`i'=matrix(r(miss))
	*putexcel D`i'=matrix(r(`total')) // figure it out wit SB 
	
	}
	local i=`i'+1
	}
	
}

*--------------------------------------------------------------------------
** Number of distinct values
*--------------------------------------------------------------------------

//Pay attention to variables with very few distinct values. 
//Lack of variation in variables is an important flag to be raised and discussed with the PIs. 

putexcel set  "`reports'/unique_values.xlsx", replace
local i=1
foreach var of varlist _all { 
	qui ta `var' 
	if `r(N)' != 0 {
	di "`var'{col 32}" %10.0f r(r) %10.0f r(N) // displays three columns: varname, no. of distinct obs, total obs
	quietly{
	putexcel A`i'=("`var'")
	putexcel B`i'=matrix(r(r))
	putexcel C`i'=matrix(r(N))
	local i=`i'+1
	}
	}
	
}

*--------------------------------------------------------------------------
** Distribution of specific coded values (don't know, refused, other etc.)
*--------------------------------------------------------------------------

qui ds, has(type numeric)
putexcel set  "`reports'/specific_values_farmer.xlsx", sheet("999_num") modify
local i=2
putexcel A1= ("Variable")
putexcel B1= ("Frequency of 999 value")
putexcel C1= ("Percentage of 999 value")
foreach var of varlist `r(varlist)' {
	qui count if `var' == 999  		
	qui di "'999' in `var'{col 32}" %10.2f (r(N)/c(N))*100 "%"
	quietly{
		putexcel A`i'=("`var'{col 32}") 
		putexcel B`i'=matrix(r(N))
		local x= (r(N)/c(N))*100
		putexcel C`i'=(`x')
	}
	local i=`i'+1
}
 
qui ds, has(type numeric)
putexcel set  "`reports'/specific_values_farmer.xlsx", sheet("888_num") modify
local i=2
putexcel A1= ("Variable")
putexcel B1= ("Frequency of 888 value")
putexcel C1= ("Percentage of 888 value")
foreach var of varlist `r(varlist)' {
	qui count if `var' == 888  		
	qui di "'888' in `var'{col 32}" %10.2f (r(N)/c(N))*100 "%" 
	quietly{
		putexcel A`i'=("`var'{col 32}") 
		putexcel B`i'=matrix(r(N))
		local x= (r(N)/c(N))*100
		putexcel C`i'=(`x')
	}
	local i=`i'+1
}

qui ds, has(type numeric) 
putexcel set  "`reports'/specific_values_farmer.xlsx", sheet("777_num") modify
local i=2
putexcel A1= ("Variable")
putexcel B1= ("Frequency of 777 value")
putexcel C1= ("Percentage of 777 value")
foreach var of varlist `r(varlist)' {
	qui count if `var' == 777  		
	qui di "'777' in `var'{col 32}" %10.2f (r(N)/c(N))*100 "%" 
	quietly{
		putexcel A`i'=("`var'{col 32}") 
		putexcel B`i'=matrix(r(N))
		local x= (r(N)/c(N))*100
		putexcel C`i'=(`x')
	}
	local i=`i'+1
}
   

qui ds, has(type string)
putexcel set  "`reports'/specific_values_farmer.xlsx", sheet("999_str") modify
local i=2
putexcel A1= ("Variable")
putexcel B1= ("Frequency of 999 value")
putexcel C1= ("Percentage of 999 value")
foreach var of varlist `r(varlist)' {
	qui count if `var' =="999" 		
	qui di "'999' in `var'{col 32}" %10.2f (r(N)/c(N))*100 "%"  
	quietly{
		putexcel A`i'=("`var'{col 32}") 
		putexcel B`i'=matrix(r(N))
		local x= (r(N)/c(N))*100
		putexcel C`i'=(`x')
	}
	local i=`i'+1
}
   
qui ds, has(type string)
putexcel set  "`reports'/specific_values_farmer.xlsx", sheet("888_str") modify
local i=2
putexcel A1= ("Variable")
putexcel B1= ("Frequency of 888 value")
putexcel C1= ("Percentage of 888 value")
foreach var of varlist `r(varlist)' {
	qui count if `var' =="888"  		
	qui di "'888' in `var'{col 32}" %10.2f (r(N)/c(N))*100 "%"  
	quietly{
		putexcel A`i'=("`var'{col 32}") 
		putexcel B`i'=matrix(r(N))
		local x= (r(N)/c(N))*100
		putexcel C`i'=(`x')
	}
	local i=`i'+1
}
   
qui ds, has(type string)
putexcel set  "`reports'/specific_values_farmer.xlsx", sheet("777_str") modify
local i=2
putexcel A1= ("Variable")
putexcel B1= ("Frequency of 777 value")
putexcel C1= ("Percentage of 777 value")
foreach var of varlist `r(varlist)' {
	qui count if `var' == "777"  		
	qui di "'777' in `var'{col 32}" %10.2f (r(N)/c(N))*100 "%" 
	quietly{
		putexcel A`i'=("`var'{col 32}") 
		putexcel B`i'=matrix(r(N))
		local x= (r(N)/c(N))*100
		putexcel C`i'=(`x')
	}
	local i=`i'+1
}
   

*==========================================================================
**************************** Survey Duration ******************************
*==========================================================================

** Calculating duration 
*keep if consent==1
gen t = endtime - starttime
gen duration_new = round(t/(1000*60),1) // duration in minutes
drop t


qui sum duration_new, d
	gen sds = (duration_new - r(mean))/r(sd) 

di "Unusually short or long survey duration:" 
list `unique' `enum' duration_new if abs(sds) > 2 & duration_new != . , abbr(32)	
cap export excel `unique' `enum' duration_new starttime endtime  using "`reports'/duration_farmer.xlsx" if abs(sds) > 2 & duration_new != ., firstrow(variables) replace
																	
drop sds 

*==========================================================================
******************Generating section wise duration ************************
*==========================================================================


local dur_var "a3_end b_end c_end d_end ag_end d7_end e_end g_end exp_end k_end l_end"
local i=1
gen double prev_sec=starttime
gen double temp_time= clock(a3_end, "YMDhms")
foreach var of varlist `dur_var'{
	replace temp_time =clock(`var', "YMDhms")
	
	gen double duration`i'= round((temp_time- prev_sec)/(1000*60),1) 
	replace prev_sec= temp_time
	local i=`i'+1
}


putexcel set  "`reports'/duration_section_wisefarmer.xlsx", replace
local num "1 2 3 4 5 6 7 8 9 10 11"
putexcel A1= ("Detail")
putexcel B1= ("Mean")
putexcel C1= ("Median")
putexcel D1= ("Min Value")
putexcel E1= ("Max value")
local j=2
foreach i in  `num' {
	quietly{
		
	summarize duration`i', detail
	return list
	putexcel A`j'= ("Section`i'")
	putexcel B`j'= (r(mean))
	putexcel C`j'= (r(p50))
	putexcel D`j'= (r(min))
	putexcel E`j'= (r(max))
	}
	local j=`j'+1
} 


*==========================================================================
***************************** Productivity ********************************
*==========================================================================

*--------------------------------------------------------------------------
** Overall Productivity
*--------------------------------------------------------------------------

*qui gen surveydate = dofc(endtime) //you can use starttime too, instead

qui bys survey_date: gen daily_avg = _N 
qui egen tag = tag(survey_date) 

// Summary of daily average productivity: 
sum daily_avg if tag 
drop tag 


** Overall Productivity histogram 

qui sum survey_date

#delimit ;

histogram survey_date, freq discrete fcolor(emidblue) width(1) lw(none) lc(white)
	xtitle(Date, height(6) si(small)) 
	ytitle(Number of Surveys, height(6) si(small)) ylabel(0 (20) 140, labsize(vsmall)) xsize(20) ysize(12)
	tlabel(`r(min)' (7) `r(max)', labsize(vsmall)) title(Surveys Per Day, si(medsmall) m(medium) c(black)) 
	scheme(vg_outc) plotr(m(zero) ifc(white)) aspect(.4); if survey_date>=23261
#delimit cr

	// Using just the first line -- histogram surveydate, freq -- will also produce a graph. The remaining part of the code is 
	// for formatting. Refer to graph twoway options in help to understand formatting. 

graph export "`reports'/productivity.jpg", as(jpg) name("Graph") quality(90) replace

/*==========================================================================
SECTION: QUESTIONNAIRE SPECIFIC HFCs
==========================================================================*/

// Control GPs where the respondent reported they received the drum seeder 
destring panchayatid, replace 
merge m:1 panchayatid using "`input'/prefill_aeo.dta"

keep if _merge!=2 
drop surveyid_str

cap export excel surveyor_id unique_id team_id survey_date key using "`reports'/controlreceiveddrumseeder_farmer.xlsx" if gp_recv_lst_rabi==1 &treat_group=="No Rentals", firstrow(variables) replace

// barrier1 should not be equal to barrier2
export excel surveyor_id unique_id survey_date team_id key using "`reports'/barrier_same_farmer.xlsx" if barrier1==barrier2, firstrow(variables) replace 

//Not heard of drum seeder and knows farmers who have used drumseeder 
export excel surveyor_id unique_id team_id survey_date key using "`reports'/not_heard_ds_knows_farmers_used_ds.xlsx" if [num_dum!=0 | !missing(num_dum)] & drum_exp ==5, firstrow(variables) replace

//If they spoke at last gram sabha meeting but did not attend last gram sabh meeting
cap export excel surveyor_id unique_id survey_date team_id key using "`reports'/spoken_at_last_gp_but_didn't_attend.xlsx" if b4_speak_metng_gp==1 & b3_lst_gram_sabh_metng==2, firstrow(variables) replace

*--------------------------------------------------------------------------
** Individual randomisation and drum seeding 
*--------------------------------------------------------------------------

* appending individual randomisation files 
import delimited "`prefill_input'/treat_assignment.csv", clear 
save "`prefill_input'/treat_assignment.dta", replace
import delimited "`prefill_input'/treat_assignment2.xlsx - Sheet1.csv", clear
save "`prefill_input'/treat_assignment2.dta", replace
import delimited "`prefill_input'/treat_assignment3.xlsx - Sheet1.csv",  clear
save "`prefill_input'/treat_assignment3.dta", replace

append using "`prefill_input'/treat_assignment2.dta", force
append using "`prefill_input'/treat_assignment.dta", force
rename ppbno unique_id
save "`prefill_input'/treat_assignment_appended.dta", replace
