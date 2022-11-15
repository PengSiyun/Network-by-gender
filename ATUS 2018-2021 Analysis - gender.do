****Priject: Age and network
****Author:  Siyun Peng
****Date started: 2022/10/17
****Version: 17
****Purpose: data analysis




***************************************************************
**# 1 data clean
***************************************************************

  

use "C:\Users\bluep\Dropbox\peng\Academia\Work with Brea\P2P\Age and network\ATUS\ATUS Analysis\ATUS 2018-2021-ROTH-10-26-22.dta",clear //home
cd "C:\Users\bluep\Dropbox\peng\Academia\Work with Brea\P2P\Age and network\ATUS\Results"

recode year (2018=1) (2019=2) (2020=3) (2021=4)
lab de year 1 "2018" 2 "2019" 3 "2020" 4 "2021"
lab val year year

recode tesex (1=0) (2=1),gen(women)
lab var women "Women"
lab de women 0 "Men" 1 "Women"
lab val women women

recode ptdtrace (1=1) (2/max=0),gen(white)
lab var white "White"
lab de white 0 "Non-White" 1 "White"
lab val white white

recode telfs (1 2=1) (3/5=0),gen(work)
lab var work "Working full time"

recode peeduca (31/38=1) (39=2) (40/42=3) (43/46=4),gen(edu)
lab def edu 1 "Less than HS" 2 "HS or GED" 3 "Some college/technical" 4 "College"
lab val edu edu
lab var edu "Education"

recode edu (1/3=0) (4=1),gen(college)
lab var college "College"

recode pemaritl (1 2=2) (3/5=3) (6=1),gen(marital)
lab def marital 1 "Never married" 2 "Married/cohabitating" 3 "Sep/Wid/Div"
lab val marital marital
lab var marital "Marital status"
recode marital (2=1) (1 3=0),gen(married)

recode pedis* (1=1) (2=0)
egen faq=rowtotal(pedis*),mi
recode faq (1/max=1)
lab var faq "Functional activities limitation"

drop if teage<18 //drop people<18 to be consistent with P2P
recode teage (18/29=2) (30/39=3) (40/49=4) (50/59=5) (60/69=6) (70/79=7) (80/max=8) ,gen(age_grp)
lab define age_grp 2 "18-29" 3 "30-39" 4 "40-49" 5 "50-59" 6 "60-69" 7 "70-79" 8 "80+" 
lab values age_grp age_grp
lab var age_grp "Age group"

recode teage (18/29=2) (30/39=3) (40/49=4) (50/59=5) (60/69=6) (70/max=7) ,gen(age_grp7)
lab define age_grp7 2 "18-29" 3 "30-39" 4 "40-49" 5 "50-59" 6 "60-69" 7 "70+" 
lab values age_grp7 age_grp7
lab var age_grp7 "Age group"

egen social_mins=rowtotal(*_mins)
foreach x of varlist *_mins {
	replace `x'=`x'/1440
}
		
		
		


	
		
***************************************************************
**# 2 regression with weights
***************************************************************




*keep if year==2019 // could only do analysis on 2019

*apply weights
replace tufinlwgt=tu20fwgt if missing(tufinlwgt) //2020 weights are in different variable
svyset [pw=tufinlwgt] //tu20fwgt: 2020 weights is different to account for COVID

*descriptive table
desctable tpartner_mins tkid_mins toth_fam_mins twrkmate_mins tothr_mins tfrnd_mins, filename("descriptives") stats(svymean semean sd range n) listwise group(year)

*percentage bar		
graph bar tpartner_mins tkid_mins toth_fam_mins twrkmate_mins tfrnd_mins tothr_mins [pw = tufinlwgt] if women==1, over(age_grp) stack percent title("Women") saving(bar_women,replace)
graph bar tpartner_mins tkid_mins toth_fam_mins twrkmate_mins tfrnd_mins tothr_mins [pw = tufinlwgt] if women==0, over(age_grp) stack percent title("Men") saving(bar_men,replace)
graph combine "bar_women" "bar_men", imargin(0 0 0 0) ycommon 
graph export "bar_composition_gender.tif", replace

graph bar tpartner_mins tkid_mins toth_fam_mins twrkmate_mins tfrnd_mins tothr_mins [pw = tufinlwgt] if women==1, over(age_grp) stack title("Women") saving(bar_women,replace)
graph bar tpartner_mins tkid_mins toth_fam_mins twrkmate_mins tfrnd_mins tothr_mins [pw = tufinlwgt] if women==0, over(age_grp) stack title("Men") saving(bar_men,replace)
graph combine "bar_women" "bar_men", imargin(0 0 0 0) ycommon 
graph export "bar_composition_num_gender.tif", replace





/*no control*/



foreach x of varlist social_mins tpartner_mins tkid_mins toth_fam_mins twrkmate_mins tfrnd_mins tothr_mins {
    svy: reg `x' i.women##i.age_grp   
margins i.women, at(age_grp=(2 (1) 8))
marginsplot, tit("") ytit("`x'") xtit("") plot1opts(color(blue)) plot2opts(color(red)) plotopt(msymbol(i)) ci1opts(color(blue%30)) ci2opts(color(red%30)) recastci(rarea) legend(off) saving(`x',replace)
}
graph combine "social_mins" "tpartner_mins" "tkid_mins" "toth_fam_mins" "twrkmate_mins" "tfrnd_mins" "tothr_mins" , ///
imargin(0 0 0 0) ycommon 
graph export "composition_nocontrol_gender.tif", replace





/*controls*/


*composition
foreach x of varlist social_mins tpartner_mins tkid_mins toth_fam_mins twrkmate_mins tfrnd_mins tothr_mins {
    svy: reg `x' i.women##i.age_grp i.white i.edu i.married i.faq i.work i.tudiaryday i.trholiday i.year
margins i.women, at(age_grp=(2 (1) 8))
marginsplot, tit("") ytit("`x'") xtit("") plot1opts(color(blue)) plot2opts(color(red)) plotopt(msymbol(i)) ci1opts(color(blue%30)) ci2opts(color(red%30)) recastci(rarea) legend(off) saving(`x',replace)
}
graph combine "social_mins" "tpartner_mins" "tkid_mins" "toth_fam_mins" "twrkmate_mins" "tfrnd_mins" "tothr_mins" , ///
imargin(0 0 0 0) ycommon 
graph export "composition_control_gender.tif", replace


		
	
		
		
		
***************************************************************
**# 3 Interaction
***************************************************************




*by marital status
foreach x of varlist social_mins tpartner_mins tkid_mins toth_fam_mins twrkmate_mins tfrnd_mins tothr_mins {
    svy: reg `x' i.women##i.age_grp##i.married i.white i.edu i.faq i.work i.tudiaryday i.trholiday i.year 
margins i.women#i.married, at(age_grp=(2 (1) 8))
marginsplot, tit("") ytit("`x'") xtit("") plot1opts(color(blue) lp(dash)) plot2opts(color(blue)) plot3opts(color(red) lp(dash)) plot4opts(color(red))  plotopt(msymbol(i))  recastci(rarea) ci1opt(color(blue%30)) ci2opt(color(blue%30)) ci3opt(color(red%30)) ci4opt(color(red%30)) legend(off) saving(`x',replace)
}
graph combine "social_mins" "tpartner_mins" "tkid_mins" "toth_fam_mins" "twrkmate_mins" "tfrnd_mins" "tothr_mins" , ///
imargin(0 0 0 0) ycommon 
graph export "composition_married_gender.tif", replace


*network relations by work
foreach x of varlist social_mins tpartner_mins tkid_mins toth_fam_mins twrkmate_mins tfrnd_mins tothr_mins {
    svy: reg `x' i.women##i.age_grp7##i.work i.white i.edu i.married i.faq i.tudiaryday i.trholiday i.year 
margins i.women#i.work, at(age_grp7=(2 (1) 7))
marginsplot, tit("") ytit("`x'") xtit("") plot1opts(color(blue) lp(dash)) plot2opts(color(blue)) plot3opts(color(red) lp(dash)) plot4opts(color(red))  plotopt(msymbol(i))  recastci(rarea) ci1opt(color(blue%30)) ci2opt(color(blue%30)) ci3opt(color(red%30)) ci4opt(color(red%30)) legend(off) saving(`x',replace)
}
graph combine "social_mins" "tpartner_mins" "tkid_mins" "toth_fam_mins" "twrkmate_mins" "tfrnd_mins" "tothr_mins" , ///
imargin(0 0 0 0) ycommon 
graph export "composition_work_gender.tif", replace


*network relations by college
foreach x of varlist social_mins tpartner_mins tkid_mins toth_fam_mins twrkmate_mins tfrnd_mins tothr_mins {
    svy: reg `x' i.women##i.age_grp##i.college i.white i.married i.faq i.work i.tudiaryday i.trholiday i.year 
margins i.women#i.college, at(age_grp=(2 (1) 8))
marginsplot, tit("") ytit("`x'") xtit("") plot1opts(color(blue) lp(dash)) plot2opts(color(blue)) plot3opts(color(red) lp(dash)) plot4opts(color(red))  plotopt(msymbol(i))  recastci(rarea) ci1opt(color(blue%30)) ci2opt(color(blue%30)) ci3opt(color(red%30)) ci4opt(color(red%30)) legend(off) saving(`x',replace)
}
graph combine "social_mins" "tpartner_mins" "tkid_mins" "toth_fam_mins" "twrkmate_mins" "tfrnd_mins" "tothr_mins" , ///
imargin(0 0 0 0) ycommon 
graph export "composition_college_gender.tif", replace


*network relations by faq
foreach x of varlist social_mins tpartner_mins tkid_mins toth_fam_mins twrkmate_mins tfrnd_mins tothr_mins {
    svy: reg `x' i.women##i.age_grp##i.faq i.white i.edu i.married i.work i.tudiaryday i.trholiday i.year 
margins i.women#i.faq, at(age_grp=(2 (1) 8))
marginsplot, tit("") ytit("`x'") xtit("") plot1opts(color(blue) lp(dash)) plot2opts(color(blue)) plot3opts(color(red) lp(dash)) plot4opts(color(red))  plotopt(msymbol(i))  recastci(rarea) ci1opt(color(blue%30)) ci2opt(color(blue%30)) ci3opt(color(red%30)) ci4opt(color(red%30)) legend(off) saving(`x',replace)
}
graph combine "social_mins" "tpartner_mins" "tkid_mins" "toth_fam_mins" "twrkmate_mins" "tfrnd_mins" "tothr_mins" , ///
imargin(0 0 0 0) ycommon 
graph export "composition_faq_gender.tif", replace

