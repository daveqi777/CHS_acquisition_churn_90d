model_doc <- function(){
  render("model_doc.rmd")
  timepoint = format(Sys.time(), "%Y-%m-%d__%H-%M-%S")
  newfile = paste0(file.path(getwd(), "Documents"), "/Model_doc", timepoint, ".html")
  file.rename("model_doc.html", newfile)
}