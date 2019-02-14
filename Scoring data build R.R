# install.packages('RODBC')
require(RODBC)
require(lubridate)
require(tidyverse)
require(Hmisc)
require(cluster)
require(rmarkdown)
library(lubridate)
options(scipen=999)
# connect to mysql
dsn = 'Staging'
conn = odbcConnect(dsn)

#######################################################################
#######################################################################
########### Part 1 - extrach base data from MySQL #####################
#######################################################################
#######################################################################

# score cohort

sql_d1 = "
set @max_first_uu = 
  (select max(first_usage_units) from bidw.customer_segmentation);
";

sql_d2 = "
set @scor_str = date_sub(@max_first_uu, interval 5  week); # - 5 weeks
";
sql_d3 = "
set @scor_end = date_sub(@max_first_uu, interval 1  week); # - 1 weeks
";

sqlQuery(conn, sql_d1)
sqlQuery(conn, sql_d2)
sqlQuery(conn, sql_d3)

# sql_temp = "drop table bidw.customer_segmentation_r;"
# sqlQuery(conn, sql_temp)

# build score data

sql_q1 = "
create temporary table bidw.customer_segmentation_m as
select distinct account_key, site, account_id, first_usage_units, last_usage_units, 
company_name, company_id, b.usage, phone, email, attribution_source,
mobile_signup, brand_used, industry, a.city, a.state, a.country, month(start_date) as start_month,
is_api, is_api_developer, month(first_usage_units) as first_usage_units_month, first_month_revenue,
contacts, number_of_contacts, is_freemium_at_signup, customer_satisfaction_pendo, 
customer_service_survey_rating, keywords_all, keywords_purchased, keyword_optins, sms_keyword_in, 
primary_sms_usecase, example_sms, google_sms_example, google_sms_class, google_sms_class_confidence,
case when phone is not null then 1 else 0 end as phone_f, 
case when email is not null and email like '%@%' then 1 else 0 end as email_f
from bidw.customer_segmentation a 
left join ez_fact.userprofiles b
on a.account_id = b.userid
where site not in ('cf2', 'tesla')
and email not like '%callfire%'
and email not like '%eztext%'
and first_usage_units >= @scor_str
and first_usage_units <= @scor_end;
";
sqlQuery(conn, sql_q1)


sql_q2 = "
create temporary table bidw.cs_usage_2w as
Select distinct cs.account_key
,datediff(DATE(FROM_UNIXTIME(processdate_est_key)), cs.first_usage_units) as days_after
,sum(df.usage_units) as usage_units_d
,sum(df.usage_dollars) as usage_dollars_d
from bidw.customer_segmentation_m cs 
join bidw.domo_account_dim dad 
on dad.site=cs.site and dad.account_id = cs.account_id
left join bidw.domo_fact df 
on df.account_key=dad.account_key 
and DATE(FROM_UNIXTIME(df.processdate_est_key)) between cs.first_usage_units and date_add(cs.first_usage_units, interval 1 week) - 1
and category in ('sms' , 'mms')
where cs.site not in ('cf2', 'tesla')
# and churn_90d is not null
# and datediff(cs.last_usage_units, DATE(FROM_UNIXTIME(processdate_est_key))) div 7 + 1 > 0
group by cs.account_key, days_after
order by cs.account_key, days_after;
";
sqlQuery(conn, sql_q2)

sqlQuery(conn, "select * from bidw.cs_usage_2w")


sql_q3 = "
create temporary table bidw.cs_usage_2wk as
select distinct account_key
#usage units
,sum(case days_after when 0 then usage_units_d else 0 end) as uu_d1
,sum(case days_after when 1 then usage_units_d else 0 end) as uu_d2
,sum(case days_after when 2 then usage_units_d else 0 end) as uu_d3
,sum(case days_after when 3 then usage_units_d else 0 end) as uu_d4
,sum(case days_after when 4 then usage_units_d else 0 end) as uu_d5
,sum(case days_after when 5 then usage_units_d else 0 end) as uu_d6
,sum(case days_after when 6 then usage_units_d else 0 end) as uu_d7
#,sum(case days_after when 7 then usage_units_d else 0 end) as uu_d8
#,sum(case days_after when 8 then usage_units_d else 0 end) as uu_d9
#,sum(case days_after when 9 then usage_units_d else 0 end) as uu_d10
#,sum(case days_after when 10 then usage_units_d else 0 end) as uu_d11
#,sum(case days_after when 11 then usage_units_d else 0 end) as uu_d12
#,sum(case days_after when 12 then usage_units_d else 0 end) as uu_d13
#,sum(case days_after when 13 then usage_units_d else 0 end) as uu_d14
#,(uu_d1 + uu_d2 + uu_d3 + uu_d4 + uu_d5 + uu_d6 + uu_d7 + uu_d8 + uu_d9 + uu_d10 + uu_d11 + uu_d12 + uu_d13 + uu_d14) as uu_2wk
# usage dollars
,sum(case days_after when 0 then usage_dollars_d else 0 end) as ud_d1
,sum(case days_after when 1 then usage_dollars_d else 0 end) as ud_d2
,sum(case days_after when 2 then usage_dollars_d else 0 end) as ud_d3
,sum(case days_after when 3 then usage_dollars_d else 0 end) as ud_d4
,sum(case days_after when 4 then usage_dollars_d else 0 end) as ud_d5
,sum(case days_after when 5 then usage_dollars_d else 0 end) as ud_d6
,sum(case days_after when 6 then usage_dollars_d else 0 end) as ud_d7
#,sum(case days_after when 7 then usage_dollars_d else 0 end) as ud_d8
#,sum(case days_after when 8 then usage_dollars_d else 0 end) as ud_d9
#,sum(case days_after when 9 then usage_dollars_d else 0 end) as ud_d10
#,sum(case days_after when 10 then usage_dollars_d else 0 end) as ud_d11
#,sum(case days_after when 11 then usage_dollars_d else 0 end) as ud_d12
#,sum(case days_after when 12 then usage_dollars_d else 0 end) as ud_d13
#,sum(case days_after when 13 then usage_dollars_d else 0 end) as ud_d14
#,(ud_d1 + ud_d2 + ud_d3 + ud_d4 + ud_d5 + ud_d6 + ud_d7 + ud_d8 + ud_d9 + ud_d10 + ud_d11 + ud_d12 + ud_d13 + ud_d14) as ud_2wk
from bidw.cs_usage_2w
group by account_key;
";
sqlQuery(conn, sql_q3)

sql_q4 = "
create temporary table bidw.up_logs_2w as
Select distinct cs.account_key
,datediff(up.createdat, cs.first_usage_units) as days_after
,count(distinct packageid) as pkgs_d
from bidw.customer_segmentation_m cs 
join ez_fact.userspackageslogs up
on cs.account_id = up.userid
and datediff(up.createdat, cs.first_usage_units) between 0 and 6
where cs.site not in ('cf2', 'tesla')
# and churn_90d is not null
# and datediff(cs.last_usage_units, DATE(FROM_UNIXTIME(processdate_est_key))) div 7 + 1 > 0
group by cs.account_key, days_after
order by cs.account_key, days_after;
";
sqlQuery(conn, sql_q4)

sql_q5 = "
create temporary table bidw.up_logs_2wk as
select distinct account_key
,sum(case days_after when 0 then pkgs_d else 0 end) as pkgs_d1
,sum(case days_after when 1 then pkgs_d else 0 end) as pkgs_d2
,sum(case days_after when 2 then pkgs_d else 0 end) as pkgs_d3
,sum(case days_after when 3 then pkgs_d else 0 end) as pkgs_d4
,sum(case days_after when 4 then pkgs_d else 0 end) as pkgs_d5
,sum(case days_after when 5 then pkgs_d else 0 end) as pkgs_d6
,sum(case days_after when 6 then pkgs_d else 0 end) as pkgs_d7
#,sum(case days_after when 7 then pkgs_d else 0 end) as pkgs_d8
#,sum(case days_after when 8 then pkgs_d else 0 end) as pkgs_d9
#,sum(case days_after when 9 then pkgs_d else 0 end) as pkgs_d10
#,sum(case days_after when 10 then pkgs_d else 0 end) as pkgs_d11
#,sum(case days_after when 11 then pkgs_d else 0 end) as pkgs_d12
#,sum(case days_after when 12 then pkgs_d else 0 end) as pkgs_d13
#,sum(case days_after when 13 then pkgs_d else 0 end) as pkgs_d14
from bidw.up_logs_2w
group by account_key;
";
sqlQuery(conn, sql_q5)

sql_q6 = "
create temporary table bidw.om_stats_2w as
Select distinct cs.account_key
,datediff(om.stamp_to_send, cs.first_usage_units) as days_after
,sum(case recipients_count when null then 0 else recipients_count end) as rpct_d
,count(om.id) as capn_d
from bidw.customer_segmentation_m cs 
join ez_fact.outgoing_messages om
on cs.account_id = om.user_id
and datediff(om.stamp_to_send, cs.first_usage_units) between 0 and 6
where cs.site not in ('cf2', 'tesla')
# and churn_90d is not null
# and datediff(cs.last_usage_units, DATE(FROM_UNIXTIME(processdate_est_key))) div 7 + 1 > 0
group by cs.account_key, days_after
order by cs.account_key, days_after;
";
sqlQuery(conn, sql_q6)


sql_q7 = "
create temporary table bidw.om_stats_2wk as
select distinct account_key
#usage units
,sum(case days_after when 0 then rpct_d else 0 end) as rpct_d1
,sum(case days_after when 1 then rpct_d else 0 end) as rpct_d2
,sum(case days_after when 2 then rpct_d else 0 end) as rpct_d3
,sum(case days_after when 3 then rpct_d else 0 end) as rpct_d4
,sum(case days_after when 4 then rpct_d else 0 end) as rpct_d5
,sum(case days_after when 5 then rpct_d else 0 end) as rpct_d6
,sum(case days_after when 6 then rpct_d else 0 end) as rpct_d7
#,sum(case days_after when 7 then rpct_d else 0 end) as rpct_d8
#,sum(case days_after when 8 then rpct_d else 0 end) as rpct_d9
#,sum(case days_after when 9 then rpct_d else 0 end) as rpct_d10
#,sum(case days_after when 10 then rpct_d else 0 end) as rpct_d11
#,sum(case days_after when 11 then rpct_d else 0 end) as rpct_d12
#,sum(case days_after when 12 then rpct_d else 0 end) as rpct_d13
#,sum(case days_after when 13 then rpct_d else 0 end) as rpct_d14
# usage dollars
,sum(case days_after when 0 then capn_d else 0 end) as capn_d1
,sum(case days_after when 1 then capn_d else 0 end) as capn_d2
,sum(case days_after when 2 then capn_d else 0 end) as capn_d3
,sum(case days_after when 3 then capn_d else 0 end) as capn_d4
,sum(case days_after when 4 then capn_d else 0 end) as capn_d5
,sum(case days_after when 5 then capn_d else 0 end) as capn_d6
,sum(case days_after when 6 then capn_d else 0 end) as capn_d7
#,sum(case days_after when 7 then capn_d else 0 end) as capn_d8
#,sum(case days_after when 8 then capn_d else 0 end) as capn_d9
#,sum(case days_after when 9 then capn_d else 0 end) as capn_d10
#,sum(case days_after when 10 then capn_d else 0 end) as capn_d11
#,sum(case days_after when 11 then capn_d else 0 end) as capn_d12
#,sum(case days_after when 12 then capn_d else 0 end) as capn_d13
#,sum(case days_after when 13 then capn_d else 0 end) as capn_d14
from bidw.om_stats_2w
group by account_key;
";
sqlQuery(conn, sql_q7)

sql_q8 = "
create temporary table bidw.customer_segmentation_m_2wk as
select distinct a.*
  ,uu_d1
,uu_d2
,uu_d3
,uu_d4
,uu_d5
,uu_d6
,uu_d7
#,uu_d8
#,uu_d9
#,uu_d10
#,uu_d11
#,uu_d12
,ud_d1
,ud_d2
,ud_d3
,ud_d4
,ud_d5
,ud_d6
,ud_d7
#,ud_d8
#,ud_d9
#,ud_d10
#,ud_d11
#,ud_d12
,pkgs_d1
,pkgs_d2
,pkgs_d3
,pkgs_d4
,pkgs_d5
,pkgs_d6
,pkgs_d7
#,pkgs_d8
#,pkgs_d9
#,pkgs_d10
#,pkgs_d11
#,pkgs_d12
,rpct_d1
,rpct_d2
,rpct_d3
,rpct_d4
,rpct_d5
,rpct_d6
,rpct_d7
#,rpct_d8
#,rpct_d9
#,rpct_d10
#,rpct_d11
#,rpct_d12
,capn_d1
,capn_d2
,capn_d3
,capn_d4
,capn_d5
,capn_d6
,capn_d7
#,capn_d8
#,capn_d9
#,capn_d10
#,capn_d11
#,capn_d12
from bidw.customer_segmentation_m a
left join bidw.cs_usage_2wk b
on a.account_key = b.account_key
left join bidw.up_logs_2wk c
on a.account_key = c.account_key
left join bidw.om_stats_2wk d
on a.account_key = d.account_key;
";
sqlQuery(conn, sql_q8)

# merge all data sets to be the score base data
base = as.tibble(sqlQuery(conn, "select * from bidw.customer_segmentation_m_2wk"))

# build outgoing messages for tm features

sql_q9 = "
create temporary table bidw.om_2w as
Select distinct user_id
,recipients_count
,message
,credits
,stamp_to_send 
from bidw.customer_segmentation_m cs 
join ez_fact.outgoing_messages om
on cs.account_id = om.user_id
and datediff(om.stamp_to_send, cs.first_usage_units) between 0 and 6
where cs.site not in ('cf2', 'tesla');
";
sqlQuery(conn, sql_q9)

om = as.tibble(sqlQuery(conn, "select * from bidw.om_2w"))


#######################################################################
#######################################################################
########### Part 2 - outgoing message text mining features ############
#######################################################################
#######################################################################

# OM features creation
om$message = tolower(as.character(om$message))
om$credits = ifelse(is.na(om$credits)|om$credits=='NA', 0, om$credits)
om_1 = om %>% 
  mutate(tm_test = ifelse(grepl('test', message), credits, 0),
         tm_stopopt = ifelse(grepl('stop|optout', message), credits, 0),
         tm_dnr = ifelse(grepl('do not reply|do-not-reply', message), credits, 0),
         tm_percoff = ifelse(grepl('%|special', message), credits, 0),
         tm_dayevnt = ifelse(grepl('tonight|today|tomorrow|night', message), credits, 0),
         tm_sale = ifelse(grepl('$|sale', message), credits, 0),
         tm_vote = ifelse(grepl('vote|ballot|polls', message), credits, 0),
         tm_ofyear = ifelse(grepl('of the year', message), credits, 0),
         tm_store = ifelse(grepl('store', message), credits, 0),
         tm_quote = ifelse(grepl('quote', message), credits, 0),
         tm_admiss = ifelse(grepl('admission', message), credits, 0),
         # tm_blackf = ifelse(grepl('', message), credits, 0),
         tm_http = ifelse(grepl('http|.com|.net', message), credits, 0),
         tm_call = ifelse(grepl('call|message|msg|text', message), credits, 0),
         tm_event = ifelse(grepl('event|rvsp|party', message), credits, 0),
         tm_coupon = ifelse(grepl('coupon|special|expire', message), credits, 0),
         tm_hire = ifelse(grepl('seeking|hire|employ|hiring|earn|career', message), credits, 0),
         tm_majevnt = ifelse(grepl('christmas|halloween|black friday|labor day|valentine', message), credits, 0),
         tm_backtsch = ifelse(grepl('back to school', message), credits, 0),
         tm_pushsale = ifelse(grepl("still time|last chance|don\\'t miss|days only|deadline|don\\'t wait|dont wait|dont miss", message), credits, 0),
         tm_prize = ifelse(grepl('prize|bonus|gift|free', message), credits, 0),
         tm_signup = ifelse(grepl('sign up', message), credits, 0),
         tm_taxref = ifelse(grepl('tax', message), credits, 0),
         tm_property = ifelse(grepl('property|house agent|real estate', message), credits, 0),
         tm_refer = ifelse(grepl('refer', message), credits, 0),
         tm_auction = ifelse(grepl('auction', message), credits, 0),
         tm_congrats = ifelse(grepl('congrat', message), credits, 0),
         tm_urgent = ifelse(grepl('urgent', message), credits, 0),
         tm_donate = ifelse(grepl('donate', message), credits, 0)
         # tm_ = ifelse(grepl('', message), credits, 0),
         # tm_ = ifelse(grepl('', message), credits, 0),
         # tm_ = ifelse(grepl('', message), credits, 0),
         # tm_ = ifelse(grepl('', message), credits, 0),
         # tm_ = ifelse(grepl('', message), credits, 0),
         # tm_ = ifelse(grepl('', message), credits, 0),
         # tm_ = ifelse(grepl('', message), credits, 0),
         # tm_ = ifelse(grepl('', message), credits, 0),
         # tm_ = ifelse(grepl('', message), credits, 0),
  )

om_2 = om_1 %>% group_by(user_id) %>% 
  summarise(	 tm_stopopt  =  sum(tm_stopopt  ),
              tm_dnr      =  sum(tm_dnr      ),
              tm_percoff  =  sum(tm_percoff  ),
              tm_dayevnt  =  sum(tm_dayevnt  ),
              tm_sale     =  sum(tm_sale     ),
              tm_vote     =  sum(tm_vote     ),
              tm_ofyear   =  sum(tm_ofyear   ),
              tm_store    =  sum(tm_store    ),
              tm_quote    =  sum(tm_quote    ),
              tm_admiss   =  sum(tm_admiss   ),
              tm_http     =  sum(tm_http     ),
              tm_call     =  sum(tm_call     ),
              tm_event    =  sum(tm_event    ),
              tm_coupon   =  sum(tm_coupon   ),
              tm_hire     =  sum(tm_hire     ),
              tm_majevnt  =  sum(tm_majevnt  ),
              tm_backtsch =  sum(tm_backtsch ),
              tm_pushsale =  sum(tm_pushsale ),
              tm_prize    =  sum(tm_prize    ),
              tm_signup   =  sum(tm_signup   ),
              tm_taxref   =  sum(tm_taxref   ),
              tm_property =  sum(tm_property ),
              tm_refer    =  sum(tm_refer    ),
              tm_auction  =  sum(tm_auction  ),
              tm_congrats =  sum(tm_congrats ),
              tm_urgent   =  sum(tm_urgent   ),
              tm_donate   =  sum(tm_donate   )
  )
om_2 = om_2 %>% rename(account_id = user_id)
rm(om, om_1)


#######################################################################
#######################################################################
########### Part 3 - merge all to build the score data ################
#######################################################################
#######################################################################

scor = base %>% left_join(om_2, by="account_id")
ind_levels = levels(scor$industry)
ind_levels[length(ind_levels)+1] = 'NA'
scor$industry = factor(scor$industry, levels=ind_levels)
scor$industry[is.na(scor$industry)] = 'NA'

# data [scor] is the final score cohort data, ready for model prediction
# saveRDS(scor, "scor.rds")