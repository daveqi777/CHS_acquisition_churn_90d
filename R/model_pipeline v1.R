model_pipeline <- function(data) {
  
  message('---------------------------')
  message('Pipeline processing start')
  message('---------------------------')
  
  # if (mp$auto_options$data_source=='R') {
  # data = readRDS(mp$auto_options$rds_loc)
  # setDT(data)
  # }
  if (mp$auto_options$y %in% names(data)) {
  setnames(data, mp$auto_options$y, 'Response')
  }
  sets = list()
  trainIndex = createDataPartition(data[data$md_sc_f=='md',]$Response, p = .7, 
                                  list = FALSE, 
                                  times = 1)
    
  sets$tran = base::subset(data, md_sc_f=='md')[trainIndex,]
  sets$test = base::subset(data, md_sc_f=='md')[-trainIndex,]
  sets$scor = base::subset(data, md_sc_f=='sc')
  
  # Run variable classification
  mp$var_class <<- NULL
  mp$var_class <<- model_varclass(input_data=sets$tran)
  message('---------------------------')
  message('Step 1 - Classification done')
  message('---------------------------')
  # Run variable cleaning - train data processing
  mp$var_clean <<- NULL
  mp$var_clean <<- model_varclean(input_data=sets$tran)
  message('---------------------------')
  message('Step 2a - Cleaning TRAN done')
  message('---------------------------')
  # Run variable cleaning - test data processing
  mp$var_clean$test <<- model_testclean(input_data=sets$test)
  # rm(sets)
  message('---------------------------')
  message('Step 2b - Cleaning TEST done')
  message('---------------------------')
  # Run variable cleaning - test data processing
  mp$var_clean$scor <<- model_testclean(input_data=sets$scor)
  rm(sets)
  message('---------------------------')
  message('Step 2C - Cleaning SCOR done')
  message('---------------------------')
  
  # Run final sets preparation
  mp$final_set <<- NULL
  mp$final_set <<- model_finalset()
  message('---------------------------')
  message('Step 3 - Final sets done')
  message('---------------------------')
  # Run variable reduction
  mp$var_reduct <<- NULL
  mp$var_reduct <<- model_varreduct()
  message('---------------------------')
  message('Step 4 - Variable reduction done')
  message('---------------------------')  
  # data <<- NULL
  # Run ensemble learnings
  mp$ml <<- NULL
  # mp$ml <<- model_ml()
  message('---------------------------')
  message('Step 5 - Ensemble learning done')
  message('---------------------------')    
  # Ouput documentaion
  # model_doc()
  message('---------------------------')
  message('Step 6 - Ouput documentation done')
  message('---------------------------')     
  
  
  message('---------------------------')
  message('Pipeline processing complete')
  message('---------------------------')
}
