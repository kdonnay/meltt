meltt_data <- function(object,columns=NULL,return_all=FALSE){
  UseMethod("meltt_data")
}

meltt_data.meltt <- function(object,columns=NULL,return_all=FALSE){

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
  if (return_all){
    out = dd2
  }else{
    out = dd2[,columns] # only select requested columns
  }
  out = out[order(out$date,out$dataset,out$event),] # order by date, if tied by dataset, then event
  if (nrow(out) > 0){
    row.names(out) = 1:nrow(out) # re-index rows
    out$dataset = dat.names[out$dataset] # restore data names
  }
  return(out)
}