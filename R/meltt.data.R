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
    columns = c('dataset','event',columns)
  }
  key = object$processed$deduplicated_index[,c("dataset","event")]
  key2 = rbind(object$processed$event_matched,object$processed$episode_matched)
  for(m in seq_along(object$inputData)){
    datset = object$inputData[[m]]
    x = datset[(datset[,'obs.count'] %in% key[key[,1]==m,2]),]
    colnames(x)[colnames(x)=='obs.count'] <- 'event'
    x2 = x[,columns[columns %in% colnames(x)]]
    if(m < length(object$inputData) & length(key2) > 0){
      for(l in seq(m+1,length(object$inputData))){
        datset2 = object$inputData[[l]]
        colnames(datset2)[colnames(datset2)=='obs.count'] <- 'event'
        mergecols = columns[columns %in% colnames(datset2)]
        if(length(mergecols)>0){
          datset2 = datset2[,colnames(datset2) %in% mergecols]
          merge_keys = key2[,c(paste0('data',m),paste0('event',m),paste0('data',l),paste0('event',l))]
          merge_keys = merge_keys[merge_keys[,1]>0 & merge_keys[,2]>0 & merge_keys[,3]>0 & merge_keys[,4]>0,]
          merge_data = subset(datset2,datset2$dataset %in% merge_keys[,3] & datset2$event %in% merge_keys[,4])[,mergecols]
          merge_keys = merge_keys[match(merge_data$event,merge_keys[,4]),] # order key to correspond with data
          merge_data[,c('dataset','event')] = merge_keys[,1:2]
          x2 = merge(x2,merge_data, by = 'event', all.x=TRUE)
          ambiguous_x = colnames(x2)[grepl('.x$',colnames(x2))]
          ambiguous_y = colnames(x2)[grepl('.y$',colnames(x2))]
          if (length(ambiguous_x) > 0){
            for(iter in 1:length(ambiguous_x)){
              x2[is.na(x2[,ambiguous_x[iter]]),ambiguous_x[iter]] = x2[is.na(x2[,ambiguous_x[iter]]),ambiguous_y[iter]]
              colnames(x2)[colnames(x2)==ambiguous_x[iter]] = substr(ambiguous_x[iter],1,nchar(ambiguous_x[iter])-2)
              x2 = x2[,colnames(x2)!=ambiguous_y[iter]]
            }
          }
        }
      }
    }
    if(m==1){out = c()}
    out = rbind.fill(out,x2)
  }
  out$dataset = sapply(out$dataset, function(x) object$inputDataNames[x])
  out = out[,c(2,1,3:ncol(out))]
  return(out)
}