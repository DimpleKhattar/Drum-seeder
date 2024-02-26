**********************************************************************
*Step 1: Set CD and locals
********************************************************************** 

global identity "C:\Users\\`c(username)'"
global present_date "20230725"

* Set your working directory to use relative references.
cd "${identity}\Dropbox\Drum Seeder Project\01_data_and_codes\05_monitoring\output\backcheck_farmer"

* Log your results.
cap log close
log using "bcstats_log.log", replace 

* ENUMERATOR, TEAMS, BACK CHECKERS
* Enumerator variable
local enum "surveyor_id"
* Enumerator Team variable
//local enumteam ""
* Back checker variable
local bcer "backchecker_id"

* DATASETS
local data_path "${identity}\Dropbox\Drum Seeder Project\01_data_and_codes\03_cleaning\output\05_prep"
* The checked and deduped  dataset that will be used for the comparison
local orig_dta "`data_path'\clean_farmer" 
* The checked and deduped backcheck dataset that will be used for the comparison
local bc_dta "`data_path'\clean_backcheck_farmer_field" 

* Unique ID*
local id "unique_id" 

* VARIABLE LISTS
* Type 1 Vars: These should not change. They guage whether the enumerator 
* performed the interview and whether it was with the right respondent. 
* If these are high, you must discuss them with your field team and consider
* disciplinary action against the surveyor and redoing her/his interviews.

local t1vars " district mandal panchayat resp_rel  q17_amt_land_acre q17_amt_land_guntas hh_members smart_apps b0_own_plots b1_plot_irrigate plotwise crop_established drum_exp prob_drum prob_direct barrier1 barrier2  primary_ag gp_recv_lst_rabi num_dum b1_interactd_sarpnch b6_agricult_advice b7_farmr_attnd_metng b8_interactd_aeo b2_lst_metng_aeo b3_attend_lst_metng b9_promoted b10_mentiond_drum_seedr b11_use_drumseedr b11_use_drumseedr_entr b16_1_start_dt e1_livestock e2_workng_oth_farm e3_salary e4_construction_wrk e5_rent_frm_properties e6_nreg_act e7_rythu_bhandu e7_kisan_yojana e7_government_schemes e7_remittances e8_textiles e9_selling_seeds e11_selling_crops e12_pension e13_nonfarmbus other_income e10_other_souce"

* Type 2 Vars: These are difficult questions to administer, such as skip 
* patterns or those with a number of examples. The responses should be the  
* same, though respondents may change their answers. Discrepanices should be 
* discussed with the team and may indicate the need for additional training.

local t2vars "lst_seasn_stord_seedr" 

* Type 3 Vars: These are key outcomes that you want to understand how 
* they're working in the field. These discrepancies are not used
* to hold surveyors accountable, but rather to gauge the stability 
* of the measure and how well your survey is performing. 

local t3vars "list_apps crops_enter" 

local keepbc "survey_date comment" 

* Variables from the original survey that you want to see in the 
* outputted .csv, but not compare.

local keepsurvey "survey_date" 


* STABILITY TESTS*
* Type 3 Variables that are continuous. The stability check is a ttest.
local ttest " " 

* Type 3 Variables that are discrete. The stability check uses signrank.
local signrank " " 

**********************************************************************
*Step 3: Compare the backcheck and original data
**********************************************************************
* Run the comparison
* Make sure to specify the enumerator, enumerator team and backchecker vars.
* Select the options that you want to use, i.e. okrate, okrange, full, filename  
* This is the code that we think will be the most applicable across projects.
* Feel free to edit and add functionality.

clear 
cd "${identity}/Dropbox/Drum Seeder Project/01_data_and_codes/05_monitoring/output/backcheck_farmer"
ipabcstats, surveydata(`orig_dta') ///
	bcdata(`bc_dta') ///
	id(`id') /// 
    t1vars(`t1vars') enumerator(`enum') backchecker(`bcer')  ///
	t2vars(`t2vars') signrank(`signrank')  ///
	t3vars(`t3vars') ttest(`ttest') ///
	filename ("error_rate_farmer_field") surveydate(starttime) bcdate(starttime)
	
return list 


