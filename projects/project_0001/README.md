**Owner**: Eldar Eminov
 
**Scrape instruction**: https://lokic.locallabs.com/scrape_tasks/1

**Dataset**: 

OLD

DB01.usa_raw.irs_nonprofit_auto_rev_list_exeption_types
DB01.usa_raw.irs_nonprofit_forms_990_series
DB01.usa_raw.irs_nonprofit_forms_990n
DB01.usa_raw.irs_nonprofit_forms_auto_rev_list
DB01.usa_raw.irs_nonprofit_forms_infos
DB01.usa_raw.irs_nonprofit_forms_pub_78
DB01.usa_raw.irs_nonprofit_orgs
DB01.usa_raw.irs_nonprofit_pub_78_deductibility_codes
DB01.usa_raw.irs_nonprofit_runs

CURRENT

DB01.woke_project.irs_non_profit__auto_rev_list
DB01.woke_project.irs_non_profit__forms_990_n
DB01.woke_project.irs_non_profit__forms_990_s
DB01.woke_project.irs_non_profit__forms_pub_78
DB01.woke_project.irs_non_profit__orgs
DB01.woke_project.irs_non_profit__runs
DB01.woke_project.irs_non_profit__runs_forms_date


**Run commands**: 

bundle exec ruby hamster.rb --grab=0001 --download

bundle exec ruby hamster.rb --grab=0001 --store

--org OR --forms

_August 2022_
