meltt.data <- function(object,columns=NULL){
  # Returns input data with duplicate entries removed.
  
  # Arguments:
  
  # object == meltt() output object
  
  # columns == vector of columns names from input data; else all columns are
  # returned
  
  if(!is.meltt(object)) stop("Object is not of class meltt")
  
  if(length(columns)==0){
    columns = c('dataset','event','date','latitude','longitude',object$taxonomy$taxonomy_names)
  }else{
    columns = c('dataset','event','date','latitude','longitude',columns)
    columns = unique(columns) # limit accidental repetition
  }
  
  key = object$processed$deduplicated_index[,c("dataset","event")] # key of deduplicated entries
  dat.names = names(object$inputData)
  
  for(i in seq_along(object$inputData)){ # Gather input data into one frame
    if(i==1){dd = c() }
    tmp = object$inputData[[i]]
    colnames(tmp)[colnames(tmp)=='obs.count'] = 'event'
    dd = rbind.fill(tmp,dd)
  }
  
  dd2 = merge(key,dd,by=c('dataset','event'),all.x=T) # merge data to key (i.e. subset)
  out = dd2[,columns] # only select requested columns
  out = out[order(out$date),] # order by date
  row.names(out) = 1:nrow(out) # re-index rows
  out$dataset = dat.names[out$dataset] # restore data names
  return(out)
}

