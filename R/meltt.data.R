meltt.data <- function(object,columns=NULL,return_all=F){
  # Returns input data with duplicate entries removed.

  # Arguments:

  # object == meltt() output object

  # columns == vector of columns names from input data; else all columns are
  # returned

  if(!is.meltt(object)) stop("Object is not of class meltt")

  if(length(columns)==0){
    if(return_all){
      all = unique(unlist(sapply(object$inputData,colnames)))
      columns = unique(c('dataset','obs.count','date','latitude','longitude',object$taxonomy$taxonomy_names,all))
      columns = all2[!all2%in% c("data.source")]
    }else{
      columns = c('dataset','obs.count','date','latitude','longitude',object$taxonomy$taxonomy_names)
    }
  }else{
    columns = c('dataset','obs.count',columns) # Return data id and event id
  }

  key = object$processed$deduplicated_index[,c("dataset","event")]
  for(m in seq_along(object$inputData)){
    datset = object$inputData[[m]]
    x = datset[(datset[,'obs.count'] %in% key[key[,1]==m,2]),]
    if(m==1){out = c()}
    x2 = x[,columns[columns %in% colnames(x)]]
    x2[,"dataset"] = object$inputDataNames[m]
    out = rbind.fill(out,x2)
  }
  colnames(out)[1:2] = c("meltt.dataID","meltt.eventID")
  return(out)
}
