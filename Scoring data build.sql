use bidw;

# check cust_seg update date
SELECT *
FROM   information_schema.tables
WHERE  TABLE_SCHEMA = 'bidw'
   AND TABLE_NAME = 'customer_segmentation';
   
select max(first_usage_units) from bidw.customer_segmentation;

# set modeling and scoring dates based on refresh date of cs.cust_seg
set @max_first_uu = 
(select max(first_usage_units) from bidw.customer_segmentation);

set @scor_str = date_sub(@max_first_uu, interval 5  week); # - 5 weeks
set @scor_end = date_sub(@max_first_uu, interval 1  week); # - 1 weeks
SET SQL_SAFE_UPDATES=0;


select @max_first_uu, @scor_str, @scor_end;

select CURDATE();

# Create the score cohort data 
create temporary table customer_segmentation_m as
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
and first_usage_units <= @scor_end
;

select * from customer_segmentation_m;

# build the dummy 90d churn flag - this is only to build same format of data with model dev dataset
alter table customer_segmentation_m
add churn_90d int(1);

alter table customer_segmentation_m
add churn_1d int(1);

/*cs usage 12w*/
create temporary table cs_usage_2w as
Select distinct cs.account_key
,datediff(DATE(FROM_UNIXTIME(processdate_est_key)), cs.first_usage_units) as days_after
,sum(df.usage_units) as usage_units_d
,sum(df.usage_dollars) as usage_dollars_d
from customer_segmentation_m cs 
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
order by cs.account_key, days_after
;

select * from cs_usage_2w limit 1000;

# account key level output
create temporary table cs_usage_2wk as
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
from cs_usage_2w
group by account_key
;

select * from cs_usage_2wk limit 200;

/*cs packages logs 12w*/
create temporary table up_logs_2w as
Select distinct cs.account_key
,datediff(up.createdat, cs.first_usage_units) as days_after
,count(distinct packageid) as pkgs_d
from customer_segmentation_m cs 
join ez_fact.userspackageslogs up
on cs.account_id = up.userid
and datediff(up.createdat, cs.first_usage_units) between 0 and 6
where cs.site not in ('cf2', 'tesla')
# and churn_90d is not null
# and datediff(cs.last_usage_units, DATE(FROM_UNIXTIME(processdate_est_key))) div 7 + 1 > 0
group by cs.account_key, days_after
order by cs.account_key, days_after
;

# account key level output
create temporary table up_logs_2wk as
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
from up_logs_2w
group by account_key
;

select * from  up_logs_2wk limit 100;

/*cs outgoing msg 12w*/
create temporary table om_stats_2w as
Select distinct cs.account_key
,datediff(om.stamp_to_send, cs.first_usage_units) as days_after
,sum(case recipients_count when null then 0 else recipients_count end) as rpct_d
,count(om.id) as capn_d
from customer_segmentation_m cs 
join ez_fact.outgoing_messages om
on cs.account_id = om.user_id
and datediff(om.stamp_to_send, cs.first_usage_units) between 0 and 6
where cs.site not in ('cf2', 'tesla')
# and churn_90d is not null
# and datediff(cs.last_usage_units, DATE(FROM_UNIXTIME(processdate_est_key))) div 7 + 1 > 0
group by cs.account_key, days_after
order by cs.account_key, days_after
;

select * from ez_fact.om_stats_2w limit 100;

# account key level output
create temporary table om_stats_2wk as
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
from om_stats_2w
group by account_key
;

select * from om_stats_2wk limit 100;

# final merged table
alter table customer_segmentation_m 
add primary key (account_key);

alter table cs_usage_2wk
add primary key (account_key);

alter table up_logs_2wk 
add primary key (account_key);

alter table om_stats_2wk
add primary key (account_key);


create temporary table customer_segmentation_m_2wk as
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
from customer_segmentation_m a
left join cs_usage_2wk b
on a.account_key = b.account_key
left join up_logs_2wk c
on a.account_key = c.account_key
left join om_stats_2wk d
on a.account_key = d.account_key
;

select * from customer_segmentation_m_2wk limit 200;

# om text mining
create temporary table om_2w as
Select distinct user_id
,recipients_count
,message
,credits
,stamp_to_send 
from customer_segmentation_m cs 
join ez_fact.outgoing_messages om
on cs.account_id = om.user_id
and datediff(om.stamp_to_send, cs.first_usage_units) between 0 and 6
where cs.site not in ('cf2', 'tesla')
;

select * from om_2w limit 2000;

# create empty score output table
CREATE TABLE IF NOT EXISTS bidw.chs_acquisition_churn_90d (
    account_id bigint(20),
    first_usage_units date, 
    churn_90d_score double,
    efft_d date,
    PRIMARY KEY (account_id)
) ;

select * from bidw.chs_acquisition_churn_90d limit 20;