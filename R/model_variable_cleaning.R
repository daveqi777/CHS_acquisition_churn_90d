# Train clean
model_varclean <- function(input_data
                           ,num_median_impute=mp$auto_options$num_median_impute
                           ,cat_mssing_impute=mp$auto_options$cat_mssing_impute){
dcl = list()
res = list()
dcl$mdcl <- input_data[, c(mp$var_class$varnums, mp$var_class$varcats), with=F]
# Calculate Missing%
dcl$miss <- as.data.frame(cbind(var=colnames(dcl$mdcl)
                                ,nmiss=sapply(dcl$mdcl, function(x) round(sum(is.na(x))/length(x),2))))
setDT(dcl$miss)
dcl$miss[, nmiss:=as.vector(nmiss)]
dcl$ncomp <- dcl$miss[nmiss>mp$auto_options$missing_perc]
dcl$mdcl[, as.vector(dcl$ncomp$var):=NULL]
# dcl$mdcp <- dcl$mdcl[, as.vector(dcl$ncomp$var), with=F]
dcl$varnums <- mp$var_class$varnums[mp$var_class$varnums %in% names(dcl$mdcl)]
dcl$varcats <- mp$var_class$varcats[mp$var_class$varcats %in% names(dcl$mdcl)]
# Calculate median - from train set non-missings
dcl$median <- as.data.frame(cbind(var=colnames(dcl$mdcl[, dcl$varnums, with=F])
                                  ,med=sapply(dcl$mdcl[, dcl$varnums, with=F], function(x) median(x, na.rm=T))))
setDT(dcl$median)
dcl$median[, mednum:=as.numeric(as.vector(med))]
dcl$mdnum <- dcl$mdcl[, dcl$varnums, with=F]
if (num_median_impute==T){
  # IF - Impute numerics misssing with median
for (i in 1:length(colnames(dcl$mdnum))) {
  varv <- colnames(dcl$mdnum)[i]
  dcl$mdnum[is.na(eval(parse(text=varv)))==T, noquote(varv):= dcl$median[var==varv]$mednum]
}} else {
  dcl$num_median_impute = F
  cat("Nums impute is not done\n")
}
dcl$mdcat <- dcl$mdcl[, dcl$varcats, with=F]
if (cat_mssing_impute==T){
# Convert cat to factor & group missing
for(j in dcl$varcats){
  pos = match(j, dcl$varcats)
  # set(dcl$mdcat, i=NULL, j=j, value=ifelse(is.na(dcl$mdcat[[j]]), paste0("NA",pos), paste0("C",pos,"|",dcl$mdcat[[j]])))
  set(dcl$mdcat, i=NULL, j=j, value=factor(dcl$mdcat[[j]]))
}} else {
  dcl$cat_mssing_impute = F
  cat("Cats impute is not done\n")
}
dcl$mds <- cbind(dcl$mdnum, dcl$mdcat)
dcl$mdtd <- cbind(input_data[, c(mp$var_class$vary, mp$var_class$id), with=F], dcl$mds)

return(list(tran=dcl$mdtd
            ,medians=dcl$median
            ,varnums=dcl$varnums
            ,varcats=dcl$varcats
            ,num_median_impute=dcl$num_median_impute
            ,cat_mssing_impute=dcl$cat_mssing_impute))
}

# Test clean 
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



