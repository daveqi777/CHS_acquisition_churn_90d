
###########################################################################################################################
# Automatic propensity model enguine - v 1.0
###########################################################################################################################

# Load modules
files <- dir(file.path(getwd(),"R"))
files <- files[substr(tolower(files),nchar(files)-1,nchar(files)) == ".r"]
sapply(file.path(getwd(),"R",files),source)

# Create model pipeline object
mp <- list()

# Load auto options
mp$auto_options <- list(verbose=T
                        ,data_source='R'  # c('R','SAS','Teradata')
                        # ,rds_loc='cs_data.Rds'
                        ,sas_loc=NULL
                        ,teradata_loc=NULL
                        ,copy_data=T # if unwant to deleted the imported, set this to T to create a temp copy
                        ,y="churn_90d"
                        ,id=c("account_id") # ID[1] is the customer identifier
                        ,np_list=c("account_key", "first_usage_units", "last_usage_units", "company_name", "email",
                                   "phone", "example_sms", "attribution_source", "first_usage_units_month",
                                   names(base)[grep('\\_(d8|d9|d10|d11|d12|d13|d14)', names(base))] # keep only first 7 days
                        )                        
                        ,num_to_cat=16
                        ,cat_to_del=100
                        ,missing_perc=0.5
                        ,num_median_impute=T
                        ,cat_mssing_impute=T
                        ,downsamp=F
                        ,downsamp_seed=13579
                        ,downsamp_perc=0.10
                        ,var_reduct_num_groups=10
                        ,var_reduct_iv_floor=0.01
                        ,resamp_seed=1000
                        ,max_cores=parallel::detectCores()
                        # Machine learning algorithm settings
                        ,rf_use=T
                        ,rf_samp_perc=0.1 # x% good are used with same amount of bads
                        ,rf_ntree=c(400,200)
                        ,rf_topNvars=15 # top N variables into final model
                        ,ada_rf_topNvars=30 # top N variables from RF into adaboost
                        ,ada_mu=0.1
                        ,ada_iter=100
                        ,ada_bag_frac=0.5
)

# Import data
if (mp$auto_options$data_source=='R') {
  data = mod
  setDT(data)
} else if (mp$auto_options$data_source=='SAS') {
  data = read_sas(mp$auto_options$sas_loc)
  scor = read_sas(mp$auto_options$scor_loc)
  data = base::rbind(data, scor)
  setDT(data)
} else {
  cat('Other data sources to be developped')
}

#########################################################
# Automation mode
model_pipeline(data=data)
#########################################################


#########################################################
# Developper mode
mp$final_set = model_finalset()
mp$var_reduct = model_varreduct()
mp$ml = model_ml()
model_doc()
#########################################################

##### Save Results #####
# saveRDS(mp, 'Final Model.Rds', compress='gzip')
# saveRDS(mp, 'Final_Model_20180213.Rds')
# write.csv(mp$ml$resullt$scor, '201707_201712_scores.csv')
saveRDS(mp, 'CHS_90d.Rds')

##### Doc supplements
# data profiling
mp$final_set$trandesc = psych::describe(mp$final_set$tran)
# top variable by decile
topvars = data.table(Variable=mp$ml$randf$rft_vartop[1:15])
# # top vars definition
topvars[Variable=='contacts', Definition:='total number of contacts']
topvars[Variable=='industry', Definition:='industry group']
topvars[Variable=='tm_sale', Definition:='total credits messaing on sale related messages']
topvars[Variable=='keyword_optins', Definition:='keyword optins']
topvars[Variable=='uu_d1', Definition:='usage units of day 1']
topvars[Variable=='tm_call', Definition:='total credits messaging - ask to call/text back']
# topvars[Variable=='first_usage_units_month', Definition:='The 6m change of total debit amount']
topvars[Variable=='tm_http', Definition:='total credits spent on messages that have website']
topvars[Variable=='rpct_d1', Definition:='total number of recipients of the day 1 messaging']
topvars[Variable=='ud_d1', Definition:='usage dollars of day 1']
# topvars[Variable=='uu_d8', Definition:='usage units of day 8']
topvars[Variable=='uu_d2', Definition:='usage units of day 2']
topvars[Variable=='tm_dayevnt', Definition:='total credits spent on event notice/invitations']
topvars[Variable=='sms_keyword_in', Definition:='sms keywords usage']
topvars[Variable=='capn_d1', Definition:='number of campaigns (different messages) of day 1']
topvars[Variable=='uu_d7', Definition:='usage units of day 7']
topvars[Variable=='uu_d3', Definition:='usage units of day 3']
# topvars[Variable=='tm_stopopt', Definition:='total credits messaging - with STOP or Optout option']
# # AF EF X
# topvars[Variable=='INDUSTRY', Definition:='The industry of the sales group']
# topvars[Variable=='ANZSIC', Definition:='The ANZSIC group']
# topvars[Variable=='IB_AF_BPD', Definition:='Flag if client has business AF product']
# topvars[Variable=='Port_Type', Definition:='Portfolio group']
# topvars[Variable=='ANZ_SIC_DIVN_X', Definition:='Industry group']
# topvars[Variable=='INT_CallReport', Definition:='Customer interaction - call report']
# topvars[Variable=='BR_LI_NUMBER_OF_BUS_AF_max', Definition:='The max of business AF products in sales group']
# topvars[Variable=='IB_AFB_YTD_AB_6m', Definition:='The 6m change of IB year to date AF balance']
# topvars[Variable=='INT_CallReport_6m', Definition:='The 6m change of call report interaction']
# topvars[Variable=='AF_Total_Rev', Definition:='The total AF revenue']
# topvars[Variable=='IB_AF_BPD_Total_Rev', Definition:='The IB AF business product revenue']
# topvars[Variable=='INT_ANN_CallReport', Definition:='Annual customer interaction - call report']
# topvars[Variable=='AssetFinance', Definition:='Flag if customer has AF products']
# topvars[Variable=='BR_LI_NUMBER_OF_BUS_AF_avg', Definition:='The average of business AF products in sales group']
# # AF Car X
# topvars[Variable=='IB_AF_BPD_YTD_Avg_Bal', Definition:='The IB business asset finance average YTD balance']
# topvars[Variable=='AF_Num_prods', Definition:='The number of AF products']
# topvars[Variable=='IB_AF_BPD_Num_prods', Definition:='The number of IB business AF products']
# topvars[Variable=='AF_Total_Rev_6m', Definition:='The 6m change of AF total revenue']
# topvars[Variable=='IB_AFB_Total_Rev_6m', Definition:='The 6m change of total IB AF business revenue']
# topvars[Variable=='SB_Insurance_Opp_6m', Definition:='The 6m change of insurance split banking opportunities']
# topvars[Variable=='IB_AF_BPD_Total_Rev', Definition:='The IB AF business product total revenue']
# topvars[Variable=='AF_YTD_Avg_Bal', Definition:='The AF YTD average balance']
###
# topvars = topvars[!is.na(Definition)]

testdecile = mp$ml$resullt$test[, c(topvars$Variable, 'RF_Decile'), with=F]
mp$ml$resullt$testdecile_value = aggregate(dplyr::select(testdecile, -RF_Decile), list(testdecile$RF_Decile), mean)
mp$ml$resullt$testdecile_value = as.data.frame(t(mp$ml$resullt$testdecile_value))
bins = ncol(mp$ml$resullt$testdecile_value)
names(mp$ml$resullt$testdecile_value) = paste0('D', c(bins:1))
rownames(mp$ml$resullt$testdecile_value)[1] = 'Top variable'
setcolorder(mp$ml$resullt$testdecile_value, c(bins:1))
mp$ml$resullt$testdecile_value = subset(mp$ml$resullt$testdecile_value, !is.na(D1))
# add definition to profiling
topvarpf = data.frame(mp$ml$resullt$testdecile_value)
topvarpf$Variable = rownames(topvarpf)
topvarpfn = left_join(topvarpf, topvars)
topvarpfn = topvarpfn[, c(bins+1,1:bins)]

# ROC plot
# mp$ml$result$roc_rf = with(mp$ml$resullt$test, pROC::roc(Response, RF_Escore))
# mp$ml$result$roc_ada = with(mp$ml$resullt$test, pROC::roc(Response, ADA_Escore))
# plot(mp$ml$result$roc_rf, main='ROC Adaboost vs RandomForest', col='blue', lty=2)
# plot(mp$ml$result$roc_ada, col='red', lty=3, add=T)
# legend('topleft', legend=c("RandomForest", "Adaboost"), col=c("blue", "red"), lty=2:3, cex=0.8, bg='lightblue')
# with(mp$ml$resullt$test, ks_plot(Response, ADA_Escore))
# Final KS & ROC
perf_eva_both = with(mp$ml$resullt$test, perf_eva(Response, RF_Escore, type = c("ks", "roc"), positive="Active|0"))
# Population stability
# plot_dist = ggplot(data=mp$ml$resullt$test, aes(x=factor(cohort), y=log(RF_Cscore))) +
#   geom_violin(alpha=0.1,aes(fill=factor(cohort))) +
#   ggtitle('Score distribution by cohort')
# plot_dens = ggplot(data=mp$ml$resullt$test, aes(log(RF_Cscore))) +
#   geom_density(alpha = 0.1, aes(fill=factor(cohort))) +
#   ggtitle('Score density overlay by cohort')

# conf = cbind(pred=ifelse(mp$ml$resullt$test$RF_Cscore>=0.4, 1, 0), actual=mp$ml$resullt$test$Response)
conf = cbind(pred=mp$ml$resullt$test$RF_Cscore, actual=mp$ml$resullt$test$Response)
# confmatrix = InformationValue::confusionMatrix(conf[,2], conf[,1], threshold=0.35)
# rownames(confmatrix) = paste('Predicted -', c('0','1'))
# colnames(confmatrix) = paste('Actual -', c('0','1'))
# confmatrix$accuracy = c(round(confmatrix[1,1]/sum(confmatrix[1,]),2), round(confmatrix[2,2]/sum(confmatrix[2,]),2))
# confmatrix

confsim = tibble()
for (thres in seq(0.2, 0.5, by=0.01)) {
  confmatrix = InformationValue::confusionMatrix(conf[,2], conf[,1], threshold=thres)
  rownames(confmatrix) = paste('Predicted -', c('0','1'))
  colnames(confmatrix) = paste('Actual -', c('0','1'))
  confmatrix$accuracy = c(round(confmatrix[1,1]/sum(confmatrix[1,]),2), round(confmatrix[2,2]/sum(confmatrix[2,]),2))
  confres = c(thres, confmatrix$accuracy)
  confsim = rbind(confsim, confres)
}
names(confsim) = c("Threshold", "Non_churn_accuracy", "Churn_accuracy")

with(confsim, {
  plot(y=Non_churn_accuracy, x=Threshold, type='l', col='blue', ylim=c(0.6, 0.9), lwd=2, 
       main="Accuracy similation with varing score threshold")
  lines(y=Churn_accuracy, x=Threshold, type='l', col='red', ylim=c(0.6, 0.9), lwd=2)
  abline(v=0.3,lty=2)
})

confoptim = InformationValue::confusionMatrix(conf[,2], conf[,1], threshold=0.3)
rownames(confoptim) = paste('Predicted -', c('0','1'))
colnames(confoptim) = paste('Actual -', c('0','1'))
confoptim$accuracy = c(round(confoptim[1,1]/sum(confoptim[1,]),2), round(confoptim[2,2]/sum(confoptim[2,]),2))

mp$ml$resullt$test %>% 
  ggplot(aes(x=RF_Cscore)) +
  geom_density(fill=I("blue"), alpha=.3)

# Render doc
render('model_documentation v1_3.Rmd')

# output
scor_output = data %>% 
  inner_join(dplyr::select(mp$ml$resullt$scor, account_id, RF_Cscore)) %>% 
  dplyr::select(account_id, mp$ml$randf$rft_vartop, RF_Cscore)
# adjust_ratio = mean(mp$ml$resullt$test$RF_Cscore)/mean(scor_output$RF_Cscore)
# scor_output$Churn_90d_score = scor_output$RF_Cscore*adjust_ratio
write.csv(scor_output, "score_cohort_CHS_v1_1.csv")


