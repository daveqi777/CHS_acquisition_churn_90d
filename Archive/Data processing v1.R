library(tidytext)
library(tidyverse)
library(lubridate)
library(DT)
library(rmarkdown)
library(topicmodels)

# Part 1 - OM features creation
om = as.tibble(read.csv('data_om_20190205.csv', header=T))
om$message = tolower(as.character(om$message))
om$credits = ifelse(is.na(om$credits)|om$credits=='NA', 0, om$credits)
om$X = NULL
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
om_2 = om_2 %>% dplyr::rename(account_id = user_id)
rm(om, om_1)

# Part 2 - base data import
base = as.tibble(read.csv('data_cs_20190205.csv', header=T))
base$X = NULL

# Part 3 - company name mining and score
# ind_score = readRDS('ind_score.rds')$ind_map
# comp = base %>% select(account_id, company_name)
# comp$company_name = tolower(as.character(comp$company_name))
# comp$company_name = ifelse(is.na(comp$company_name )|comp$company_name =='NA'|comp$company_name =='', 'namemissing', comp$company_name)
# comp$company_name = gsub('\\.|\\,', ' ', comp$company_name)
# comp$company_name = gsub('\\d', '', comp$company_name)
# comp_df = comp %>% unnest_tokens(word, company_name, drop=F)
# data("stop_words")
# 
# comp_df = comp_df %>% 
#   anti_join(stop_words) %>% 
#   left_join(ind_score, by="word")

# Part 4 - join base with feature
mod = base %>% left_join(om_2, by="account_id")
ind_levels = levels(mod$industry)
ind_levels[length(ind_levels)+1] = 'NA'
mod$industry = factor(mod$industry, levels=ind_levels)
mod$industry[is.na(mod$industry)] = 'NA'
  


