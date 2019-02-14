
libs <- list(
  "data.table"
  ,"ggplot2"
  ,"rpart"
  ,"randomForest"
  ,"MASS"
  ,"rpart.plot"
  ,"plyr"
  ,"dplyr"
  ,"reshape"
  ,"reshape2"
  ,"InformationValue"
  ,"smbinning"
  ,"haven"
  ,"scales"
  ,"rmarkdown"
  ,"revealjs"
  ,"psych"
  ,"Hmisc"
  ,"grid"
  ,"gridExtra"
  ,"stringr"
  ,"tidyr"
  ,"DT"
  ,"corrplot"
  ,"FactoMineR"
  ,"ROSE"
  ,"shiny"
  ,"splitstackshape"
  ,"riv"
  ,"parallelMap"
  ,"scorecard"
  ,"caret"
  ,"pROC"
  ,"RODBC"
)

libcheck <- function(x){
  if (require(x, character.only=T)==T) {cat(paste("pakcage",x,"has been loaded"),"\n")
  } else {
    install.packages(x, quiet=T)
    suppressMessages(suppressWarnings(require(x, character.only=T)))
  } 
}

sapply(libs, libcheck)

# Rpackages ref : https://rdrr.io/all/
