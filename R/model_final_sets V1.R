# downsample tran 
model_finalset <- function(input_tran=mp$var_clean$tran
                           ,input_test=mp$var_clean$test
                           ,input_scor=mp$var_clean$scor
                           ,downsamp=mp$auto_options$downsamp
                           ,seed=mp$auto_options$downsamp_seed
                           ,perc=mp$auto_options$downsamp_perc
                           ,varnums=mp$var_clean$varnums
                           ,varcats=mp$var_clean$varcats){
  tran = copy(input_tran)
  test = copy(input_test)
  scor = copy(input_scor)
  set.seed(seed)
  if (downsamp==T) {
    # Train set - Stratified downsampling - 100% goods and x% bads where x = option$downsamp_perc, based on segment and cohort
    tranA = tran %>% 
      mutate(rd=runif(nrow(mp$var_clean$tran), 0, 1)) %>% 
      filter(rd<=perc) %>% 
      dplyr::select(-rd)
    # tranB = tran %>% 
    #   subset(Response==1)
    tran = data.table(tranA)
      if (mp$auto_options$verbose==T) {
  cat("Tran set is downsampled\n")
      }
  } else {
      if (mp$auto_options$verbose==T) {
  cat("Tran set is not downsampled\n")
      }
  }
  # cat(rep("-",14), '\n')
  # Remove test entries with out-of-scope cats values
  varcats = varcats[varcats!="md_sc_f"]
  for (i in varcats) {
    testvalues = unlist(unique(test[, i, with=F]))
    tranvalues = unlist(unique(tran[, i, with=F]))
    excepts = setdiff(testvalues, tranvalues)
    if (length(excepts)>0) {
      cat(excepts, '\n')
      n_before = nrow(test)
      test = test[!eval(parse(text=i)) %in% excepts]
      n_after = nrow(test)
      cat(paste(n_before-n_after,"rows are removed due to test values out of scope"), '\n')
    }
  }
  
  # Remove scor entries with out-of-scope cats values
  for (i in varcats) {
    scorvalues = unlist(unique(scor[, i, with=F]))
    tranvalues = unlist(unique(tran[, i, with=F]))
    excepts = setdiff(scorvalues, tranvalues)
    if (length(excepts)>0) {
      cat(i, '\n')
      cat(excepts, '\n')
      n_before = nrow(scor)
      scor = scor[!eval(parse(text=i)) %in% excepts]
      n_after = nrow(scor)
      cat(paste(n_before-n_after,"rows are removed due to scor values out of scope"), '\n')
      
    }
  }
  
  # Covert cats to factor
  tran = as.data.frame(tran)
  test = as.data.frame(test)
  scor = as.data.frame(scor)
  for (i in seq_len(ncol(tran))) {
    if (is.factor(tran[,i])==T | is.character(tran[,i])==T) {
      tran[,i] = factor(tran[,i])
    } 
    if (is.factor(test[,i])==T | is.character(test[,i])==T) {
      test[,i] = factor(test[,i], levels=unique(levels(tran[,i])))
    }
    if ((!names(scor)[i]==mp$auto_options$id[1]) & (is.factor(scor[,i])==T | is.character(scor[,i])==T)) {
      scor[,i] = factor(scor[,i], levels=unique(levels(tran[,i])))
    }
  }
  
  setDT(tran)
  setDT(test)
  setDT(scor)
  
  # cat(rep("-",30), '\n')
  # Remove single levels
  # varlvls.tran <- data.frame(var=names(tran), lvl=sapply(tran, function(x) length(unique(x))))
  # vardels.tran <- as.vector(varlvls.tran$var)[which(varlvls.tran$lvl==1)]
  # vardels.test = c()
  # cat("Test singlar variable detection by cohort", '\n','\n')
  # for (i in unique(test$cohort)){
  #   testcor = test[cohort==i]
  #   varlvls.testcor <- data.frame(var=names(testcor), lvl=sapply(testcor, function(x) length(unique(x))))
  #   vardels.testcor <- as.vector(varlvls.testcor$var)[which(varlvls.testcor$lvl==1)]
  #   vardels.testcor = vardels.testcor[!vardels.testcor %in% "cohort"]
  #   cat(paste(paste("Test corhort", i, "-"), paste0(vardels.testcor, collapse="+")), '\n')
  #   vardels.test = c(vardels.test, vardels.testcor)
  # }
  # vardels <- c(vardels.tran, vardels.test)
  # vardels = unique(vardels)
  # vardels = vardels[!vardels %in% c("cohort","Response")]
  # tran[, as.vector(vardels):=NULL]
  # test[, as.vector(vardels):=NULL]
  # cat(rep("-",30), '\n')
  # cat(paste(vardels), "are removed", '\n')
  # cat(rep("-",30), '\n')
  # varnums = varnums[!varnums %in% vardels]
  # varcats = varcats[!varcats %in% vardels]
  # Rename the cat names for PCA prediction use
  # for(j in varcats){
  #   set(test, i=NULL, j=j, value=paste0(j,"=",test[[j]]))
  # }

return(list(tran=tran, test=test, scor=scor, varnums=varnums, varcats=varcats))
}

# Revove variables that have 1 unique levels for any given period?