# packages admin
files <- dir(file.path(getwd(),"R"))
files <- files[substr(tolower(files),nchar(files)-1,nchar(files)) == ".r"]
sapply(file.path(getwd(),"R",files),source)

scoring_process <- function(verbose) {

    if (exists("scor")==T) {
      message('The score data files exist, good to proceed')
    } else {
      stop('Score data files NOT exist, process stop and revise data build')
    }
    # read in model project
    mp <- NULL
    mp = readRDS(file.path(getwd(), "CHS_90d.Rds"))
    message('Model object is read in')
    # create scor list
    sc <- list()
    # read in scoring set
    sc$scor <- setDT(scor)
    sc$scor$Response = numeric()
    sc$scor$churn_1d = numeric()
    # Step 1 - scoring set clean
    model_testclean <- function(input_data
                                ,num_median_impute=mp$auto_options$num_median_impute
                                ,cat_mssing_impute=mp$auto_options$cat_mssing_impute
                                ,medians=mp$var_clean$medians){
      ddcl <- list()
      setDT(medians)
      ddcl$ttcl <- input_data[, c(mp$var_clean$varnums, mp$var_clean$varcats), with=F]
      ddcl$ttnum <- ddcl$ttcl[, mp$var_clean$varnums, with=F]
      if (num_median_impute==T){
        # Test - Impute numerics misssing with median
        for (i in 1:length(colnames(ddcl$ttnum))) {
          varv <- colnames(ddcl$ttnum)[i]
          ddcl$ttnum[is.na(eval(parse(text=varv)))==T, noquote(varv):= medians[var==varv]$mednum]
        }}
      ddcl$ttcat <- ddcl$ttcl[, mp$var_clean$varcats, with=F]
      if (cat_mssing_impute==T){
        # Test - Convert cat to factor & group missing
        for(j in mp$var_clean$varcats){
          pos = match(j, mp$var_clean$varcats)
          # set(ddcl$ttcat, i=NULL, j=j, value=ifelse(is.na(ddcl$ttcat[[j]]), paste0("NA",pos), paste0("C",pos,"|",ddcl$ttcat[[j]])))
          set(ddcl$ttcat, i=NULL, j=j, value=factor(ddcl$ttcat[[j]]))
        }}
      ddcl$mdt <- cbind(ddcl$ttnum, ddcl$ttcat)
      ddcl$mdtt <- cbind(input_data[, c(mp$var_class$vary, mp$var_class$id), with=F], ddcl$mdt)
      setDT(ddcl$mdtt)
      return(ddcl$mdtt)
    }
    
    sc$scor_clean <- model_testclean(input_data=sc$scor)
    message('Scoring data cleaning done')
    # Step 2 - scoring set final set
    
    score_finalset <- function(input_tran=mp$final_set$tran
                               ,input_scor=sc$scor_clean
                               ,varnums=mp$final_set$varnums
                               ,varcats=mp$final_set$varcats){
      varnums = varnums[which(!varnums %in% mp$var_reduct$iv_fail_vars)]
      varcats = varcats[which(!varcats %in% mp$var_reduct$iv_fail_vars)]
      tran = copy(input_tran)
      scor = copy(input_scor)
      scor = scor[, names(tran), with=F]
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
      scor = as.data.frame(scor)
      for (i in seq_len(ncol(tran))) {
        if ((!names(scor)[i]==mp$auto_options$id[1]) & (is.factor(scor[,i])==T | is.character(scor[,i])==T)) {
          scor[,i] = factor(scor[,i], levels=unique(levels(tran[,i])))
        }
      }
      
      setDT(scor)
      return(scor)
    }
    sc$scor_final = score_finalset()
    message('Scoring data final set done')
    # Step 3 - ML
    score_ml <- function(scors=sc$scor_final
                         ,ml_var=mp$ml$randf$rft_varscope
                         ,ml_mod=mp$ml$randf$rftop
                         ,cl_mod=mp$ml$randf$rf_calm){
      # apply models
      scorpd = copy(data.table(scors))
      scorpd = scorpd[, c("account_id", ml_var), with=F]
      scorpd[, RF_Escore:=as.numeric(predict(ml_mod, newdata=scorpd, type='prob')[,2])]
      scorpd[, RF_Cscore:=predict(cl_mod, scorpd, type='response')]
      return(scorpd)
    }
    sc$scor_result <- score_ml()
    message('Scoring data ML prediction done')
    
    return(sc$scor_result)
}

# processing
pred_90d = scoring_process()
pred_90d_f = pred_90d[, c("account_id", "RF_Cscore"), with=F]
setnames(pred_90d_f, "RF_Cscore", "churn_90d_score")

# Create final output
output = scor %>% 
  select(account_id, first_usage_units) %>% 
  inner_join(pred_90d_f) %>% 
  mutate(efft_d = Sys.Date())

values = paste0(apply(output, 1, function(x) paste0("('", paste0(x, collapse = "', '"), "')")), collapse = ", ")
score_load = paste0("INSERT INTO bidw.chs_acquisition_churn_90d VALUES ", values, ";")

# load scores by insert values - using the connection in scoring data build 
sqlQuery(conn, score_load)
