model_pca <- function(tran=mp$final_set$tran
                      ,test=mp$final_set$test
                      ,varnums=mp$final_set$varnums
                      ,varcats=mp$final_set$varcats
                      ,percent=95){
  trannum = as.data.frame(tran[, varnums, with=F])
  trancat = as.data.frame(tran[, varcats, with=F])
  # Build raw mod and determine cutoff levels
  mod = PCAmix(trannum, trancat, graph=FALSE, rename.level=TRUE)
  cat("PCA raw model is built", '\n')
  dim = as.integer(which(mod$eig[,3]>=percent)[1])
  cat(paste(dim,"dimentions are selected as at",percent,"% of total variance"), '\n')
  model = PCAmix(trannum, trancat, ndim=dim, graph=FALSE, rename.level=TRUE)
  cat("PCA model is built", '\n')
  # Rotate tran/test
  pcatran <- predict.PCAmix(model, trannum, trancat, rename.level=TRUE)
  cat("Tran set is rotated", '\n')
  pcatest = matrix(nrow=0, ncol=ncol(pcatran))
  pcatesty = data.table()
  for (i in unique(test$cohort)){
    testcor = test[cohort==i]
    testcornum = as.data.frame(testcor[, varnums, with=F])
    testcorcat = as.data.frame(testcor[, varcats, with=F])
    pcatestcor <- predict.PCAmix(model, testcornum, testcorcat, rename.level=TRUE)
    pcatest = cbind(testcor[, c(mp$var_class$vary, mp$var_class$id), with=F], pcatestcor)
    pcatesty = rbind(pcatesty, pcatest)
    cat(paste("Cohort",i,"is rotated and added to the test set master","\n"))
  }
  cat("PCA prediction is completed", '\n')  
  restran = cbind(tran[, mp$var_class$vary, with=F], pcatran)
  restestid = pcatesty
  restest = copy(pcatesty)[, mp$var_class$id:=NULL]
  return(list(tran=restran, test=restest, testid=restestid, curve=mod$eig))
}