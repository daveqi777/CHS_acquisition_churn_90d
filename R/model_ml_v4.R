model_ml <- function(tran=mp$final_set$tran
                     ,test=mp$final_set$test
                     ,scor=mp$final_set$scor
                     ,algorithm=c("RF", "GBM", "GLM")){
  # tran =  mp$final_set$tran
  # test = mp$final_set$test                                         
  tran = as.data.frame(tran)
  test = as.data.frame(test)
  scor = as.data.frame(scor)
  alg = match.arg(algorithm, choices = c("RF", "GBM", "GLM"), several.ok = T)
  samp_perc = mp$auto_options$rf_samp_perc
  topNvars = mp$auto_options$rf_topNvars
  scopeNvars = mp$auto_options$ada_rf_topNvars
  ntree = mp$auto_options$rf_ntree
  # test_max_cohort = max(test$cohort)
  seed=mp$auto_options$downsamp_seed
  
  #############################################################################################
  # Start building RandomForest model
  #############################################################################################
  set.seed(seed)
  sampsize = round(sum(tran$Response)*samp_perc)
  # Raw model 
  randf = list()
  randf$rft <- randomForest(y=as.factor(tran$Response)
                      ,x=tran[3:ncol(tran)]
                      ,keep.forest=TRUE
                      ,importance=TRUE
                      ,ntree=ntree[1]
                      ,sampsize=c(sampsize, sampsize)
  )
  randf$rft_Plot = plot(randf$rft)
  randf$rft_varImpPlot <- varImpPlot(randf$rft)
  randf$rft_varImp <- as.data.frame(importance(randf$rft))[, c(3,4)]
  randf$rft_varImp <- randf$rft_varImp[order(-randf$rft_varImp$MeanDecreaseGini),][, c(2,1)]
  randf$rft_vartop <- rownames(randf$rft_varImp[c(1:topNvars),])
  randf$rft_varscope <- rownames(randf$rft_varImp[c(1:scopeNvars),])
  randf$rft_mdtop <- copy(setDT(tran))[, c("Response", randf$rft_vartop), with=F]
  randf$rftop <- randomForest(y=as.factor(randf$rft_mdtop$Response)
                        ,x=randf$rft_mdtop[, 2:ncol(randf$rft_mdtop), with=F]
                        ,keep.forest=TRUE
                        ,importance=TRUE
                        ,ntree=ntree[2]
                        ,sampsize=c(sampsize, sampsize)
  )
  # Training Gini
  tranpd = copy(data.table(tran))
  tranpd[, RF_Escore:=as.numeric(predict(randf$rftop, type='prob')[,2])]
  randf$rf_tranGini = tranpd[, round(as.numeric(rcorr.cens(RF_Escore, Response)['Dxy']),4)]
  # Testing Gini
  testpd = copy(data.table(test))
  testpd = testpd[!is.na(Response), c("Response", randf$rft_varscope), with=F]
  testpd[, RF_Escore:=as.numeric(predict(randf$rftop, newdata=testpd, type='prob')[,2])]
  randf$rf_testGini = testpd[, round(as.numeric(rcorr.cens(RF_Escore, Response)['Dxy']),4)]
  randf$rf_Gini = rbind(randf$rf_tranGini, randf$rf_testGini)
  names(randf$rf_Gini)[2] = "RF_GINI"
  # calibration 
  randf$rf_raw <- calibration(as.factor(Response)~RF_Escore, data = testpd, class='1')
  randf$rf_calm <- glm(Response~RF_Escore, family=binomial(link='logit'), data=testpd)
  testpd$RF_Cscore = predict(randf$rf_calm, testpd, type='response')
  # plots - raw vs calibrated
  par(mfrow=c(2,2))
  randf$rf_p0 = xyplot(randf$rf_raw, main='RF Raw vs Observed')
  randf$rf_p1 = xyplot(RF_Escore~RF_Cscore, data=testpd, main='Raw vs Calibrated')
  randf$rf_p2 = densityplot(testpd$RF_Escore, main= paste('RF Raw model scores with avg(score) =', round(mean(testpd$RF_Escore),3)))
  randf$rf_p3 = densityplot(testpd$RF_Cscore, main= paste('RF Calibrated scores with avg(score) =', round(mean(testpd$RF_Cscore),3)))
  randf$rf_calmPlot = gridExtra::grid.arrange(randf$rf_p2, randf$rf_p3, randf$rf_p0, randf$rf_p1, ncol=2)
  par(mfrow=c(1,1))
  # Optimal binning
  randf$rf_tranOptBin <- smbinning(df=tranpd, y="Response", x="RF_Escore", p=0.01)
  randf$rf_testOptBin <- smbinning(df=testpd, y="Response", x="RF_Cscore", p=0.01)
  randf$rf_testOptBin_Last <- smbinning(df=testpd, y="Response", x="RF_Cscore", p=0.01)
  # Deciles view
  testpd$RF_Decile = cut2(testpd$RF_Cscore, g=10)
  randf$rf_testDecile = testpd[, .(Convertion=base::round(sum(Response)/.N,4)), by=RF_Decile][order(-RF_Decile),]
  
  #############################################################################################
  # Start building FastAdaboost
  #############################################################################################
  # ada <- list()
  # ada$vartop <- rownames(randf$rft_varImp[c(1:scopeNvars),])
  # ada$mdtop <- copy(setDT(tran))[, c(names(tran)[1:4], ada$vartop), with=F]
  # ada$mdtop$Response = as.factor(ada$mdtop$Response)
  # # fast adaboost standalone
  # ada$f = as.formula(paste("Response ~ ", paste0(names(ada$mdtop)[3:ncol(ada$mdtop)], collapse='+')))
  # ada$abtop <- adaboost(ada$f
  #                       ,as.data.frame(ada$mdtop)
  #                       ,nIter = mp$auto_options$ada_iter
  #                       ,nu = mp$auto_options$ada_mu
  #                       ,bag.frac = mp$auto_options$ada_mu
  # )
  # ada$mdtop$ADA_Escore = as.numeric(predict(ada$abtop, newdata=ada$mdtop, type='prob')$prob[,2])
  # # ada$tranGini = ada$mdtop[, round(as.numeric(rcorr.cens(ADA_Escore, Response)['Dxy']),4), by=cohort]
  # testpd$ADA_Escore = as.numeric(predict(ada$abtop, newdata=testpd, type='prob')$prob[,2])
  # ada$testGini = testpd[, round(as.numeric(rcorr.cens(ADA_Escore, Response)['Dxy']),4)]
  # # calibration 
  # ada$raw <- calibration(as.factor(Response)~ADA_Escore, data = testpd, class='1')
  # ada$calm <- glm(Response~ADA_Escore, family=binomial(link='logit'), data=testpd)
  # testpd$ADA_Cscore = predict(ada$calm, testpd, type='response')
  # # plots - raw vs calibrated
  # par(mfrow=c(2,2))
  # ada$p_p0 = xyplot(ada$raw, main='ADA Raw vs Observed')
  # ada$p_p1 = xyplot(ADA_Escore~ADA_Cscore, data=testpd, main='Raw vs Calibrated')
  # ada$p_p2 = densityplot(testpd$ADA_Escore, main= paste('ADA Raw model scores with avg(score) =', round(mean(testpd$ADA_Escore),3)))
  # ada$p_p3 = densityplot(testpd$ADA_Cscore, main= paste('ADA Calibrated scores with avg(score) =', round(mean(testpd$ADA_Cscore),3)))
  # ada$p_calmPlot = gridExtra::grid.arrange(ada$p_p2, ada$p_p3, ada$p_p0, ada$p_p1, ncol=2)
  # par(mfrow=c(1,1))
  # # Optimal binning
  # # randf$rf_tranOptBin <- smbinning(df=tranpd, y="Response", x="RF_Escore", p=0.01)
  # ada$testOptBin <- smbinning(df=testpd, y="Response", x="ADA_Cscore", p=0.01)
  # # ada$testOptBin_Last <- smbinning(df=testpd[cohort==test_max_cohort], y="Response", x="ADA_Cscore", p=0.01)
  # # Deciles view
  # testpd$ADA_Decile = cut2(testpd$ADA_Cscore, g=10)
  # ada$testDecile = testpd[, .(Convertion=base::round(sum(Response)/.N,4)), by=ADA_Decile][order(-ADA_Decile),]
  
  # Scoring
  scorpd = copy(data.table(scor))
  scorpd = scorpd[, c("account_id", randf$rft_varscope), with=F]
  scorpd[, RF_Escore:=as.numeric(predict(randf$rftop, newdata=scorpd, type='prob')[,2])]
  # scorpd[, ADA_Escore:=as.numeric(predict(ada$abtop, newdata=scorpd, type='prob')$prob[,2])]
  scorpd[, RF_Cscore:=predict(randf$rf_calm, scorpd, type='response')]
  
  return(list(randf=randf, resullt=list(tran=tranpd, test=testpd, scor=scorpd)))
}
