
# Variable classification
model_varclass <- function(input_data
                           ,nplist=mp$auto_options$np_list
                           ,y="Response"
                           ,id=mp$auto_options$id
                           ){
  data = list()
  data$allvarnames = colnames(input_data)
  data$allvarclass = sapply(input_data, function(x) {class(x)})
  data$varclass = data.table(var=colnames(input_data), class=data$allvarclass)
  data$nplist = nplist
  data$y = y
  data$id = id
  data$varclass[class %in% c("integer", "numeric"), type:="num"]
  data$varclass[class %in% c("factor", "character"), type:="cat"]
  data$varclass[var %in% data$nplist, type:="np"]
  data$varclass[var %in% data$y, type:="y"]
  data$varclass[var %in% data$id, type:="id"]
  data$varnum <- data$varclass[type=="num"]$var
  data$varcat <- data$varclass[type=="cat"]$var
  data$varsummary <- table(data$varclass$type)
  # Num cleansing - Delete variables with constant value - 1 unique level only
  data$varnumlvls <- as.data.frame(sapply(input_data[, data$varnum, with=F], function(x) length(unique(x))))
  data$varnumdel <- rownames(data$varnumlvls)[which(data$varnumlvls==1)]
  data$varnumcat <- rownames(data$varnumlvls)[which(data$varnumlvls>1&data$varnumlvls<=mp$auto_options$num_to_cat)]
  data$varclass[var %in% data$varnumdel, type:="np"]
  # data$varclass[var %in% data$varnumcat, type:="cat"]
  data$varnum <- data$varclass[type=="num"]$var
  data$varcat <- data$varclass[type=="cat"]$var
  # Cat cleansing - remove variables with more than X unique levels or 1 unique levels
  data$varcatlvls <- as.data.frame(sapply(input_data[, data$varcat, with=F], function(x) length(unique(x))))
  data$varcatdel <- rownames(data$varcatlvls)[which(data$varcatlvls==1|data$varcatlvls>mp$auto_options$cat_to_del)]
  data$varclass[var %in% data$varcatdel, type:="np"]
  # Final var list
  data$varsummary <- table(data$varclass$type)
  data$varnums <- data$varclass[type=="num"]$var
  data$varcats <- data$varclass[type=="cat"]$var
  data$varnps  <- data$varclass[type=="np"]$var
  data$vary  <- data$varclass[type=="y"]$var
  if (mp$auto_options$verbose==T) {
  print(data$varsummary)
  }
  return(data)
}