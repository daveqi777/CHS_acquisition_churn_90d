model_varreduct <- function(input_data=mp$final_set$tran
                            ,num_groups=mp$auto_options$var_reduct_num_groups
                            ,iv_floor=mp$auto_options$var_reduct_iv_floor
                            ){
  var_num = c()
  iv_num = c()
  var_cat = c()
  iv_cat = c()
  
  for (i in seq_len(length(mp$final_set$varnums))){
    var_num[i] = mp$final_set$varnums[i]
    xy = mp$final_set$tran[, c(mp$final_set$varnums[i], "Response"), with=F]
    xy[, bins:= cut2(unlist(as.vector(xy[,1])), g=10)]
    iv_num[i] = IV(X=xy$bins, Y=xy$Response)
  }
  iv_res_num = as.data.frame(cbind(var_num, iv_num))
  iv_res_num[, 2] = as.numeric(as.character(iv_res_num[, 2]))
  names(iv_res_num) = c("var", "iv")
  
  for (i in seq_len(length(mp$final_set$varcats))){
    var_cat[i] = mp$final_set$varcats[i]
    xy = mp$final_set$tran[, c(mp$final_set$varcats[i], "Response"), with=F]
    names(xy)[1] = "bins"
    iv_cat[i] = IV(X=xy$bins, Y=xy$Response)
  }
  iv_res_cat = as.data.frame(cbind(var_cat, iv_cat))
  iv_res_cat[, 2] = as.numeric(as.character(iv_res_cat[, 2]))
  names(iv_res_cat) = c("var", "iv")
  
  iv_sum = rbind(iv_res_num, iv_res_cat)
  iv_fail_vars = iv_sum$var[which(iv_sum$iv<iv_floor)]
  # Do the reduction in final sets
  mp$final_set$tran <<- mp$final_set$tran[, as.vector(iv_fail_vars):=NULL]
  mp$final_set$test <<- mp$final_set$test[, as.vector(iv_fail_vars):=NULL]
  mp$final_set$scor <<- mp$final_set$scor[, as.vector(iv_fail_vars):=NULL]
  
  if (mp$auto_options$verbose==T) {cat(paste0(length(iv_fail_vars), " variables are dropped", '\n'))}
  return(list(iv_fail_vars=iv_fail_vars
              ,iv_sum=iv_sum))
}