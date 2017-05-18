meltt.duplicates = function(object,columns=NULL){
  # Returns input data retaining only to duplicative entries. The function
  # provides users with an easy way to qualitatively assess overlap.

  # Arguments:

  # object == meltt() output object

  # columns == vector of columns names from input data

  if(!is.meltt(object)) stop("Object is not of class meltt")

  if(length(columns)==0){ # Determine Relevant Columns
    for(m in seq_along(object$inputData)){columns = c(columns,colnames(object$inputData[[m]]))}
    columns = unique(columns)
    columns = c('dataset','obs.count',columns[!columns %in% c('dataset','obs.count')])
  }else{
    columns = c('dataset','obs.count',columns) # Return data id and event id
  }

  # Recover Matched Events
  event_to_event = object$processed$event_matched
  episode_to_episode = object$processed$episode_matched
  key = rbind(event_to_event,episode_to_episode)
  data_key = key[,seq_along(key) %% 2 != 0]
  obs_key = key[,seq_along(key) %% 2 == 0]
  input_data = object$inputData
  key$match_type = c(rep("event_to_event",nrow(event_to_event)),
                     rep("episode_to_episode",nrow(episode_to_episode)))

  # Locate relevant columns and bind
  for(d in ncol(data_key):1){
    consider = input_data[[d]]
    consider = consider[consider$obs.count %in% obs_key[,d],]
    consider2 = consider[,colnames(consider) %in% columns]
    colnames(consider2)[!colnames(consider2) %in% c("dataset","obs.count")] = paste(object$inputDataNames[d],colnames(consider2)[!colnames(consider2) %in% c("dataset","obs.count")],sep = "_")
    if(d==ncol(data_key)){
      out = merge(key,consider2,
                  by.x=c(paste0("data",d),paste0("event",d)),
                  by.y=c("dataset","obs.count"),all.x=T)
    }else{
      out = merge(out,consider2,
                  by.x=c(paste0("data",d),paste0("event",d)),
                  by.y=c("dataset","obs.count"),all.x=T)
    }
  }
  # Generate Unique IDs
  colnames(out)[colnames(out) %in% colnames(data_key)] = paste0(object$inputDataNames,"_dataID")
  colnames(out)[colnames(out) %in% colnames(obs_key)] = paste0(object$inputDataNames,"_eventID")
  return(out)
}
