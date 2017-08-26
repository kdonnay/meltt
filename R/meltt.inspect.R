meltt.inspect = function(object,columns=NULL,confirmed_matches=NULL){

  # Function to Inspect Flagged Event-to-Episode Detected Matches

  if(!is.meltt(object)) stop("Object is not of class meltt")

  orig_columns = columns
  dedup = object$processed$deduplicated_index
  suspects = dedup[dedup$episodal_match != "",]

  if(length(columns)==0){
    columns = c('data.source','dataset','obs.count','date','enddate','latitude','longitude',object$taxonomy$taxonomy_names)
  }else{
    columns = unique(c('data.source','dataset','obs.count','date','enddate',columns)) # Return data id and event id
  }

  key = data.frame(dataset = -99,obs.count=-99)
  for(d in seq_along(object$inputData)){
    idat = object$inputData[[d]]
    tmp = idat[,columns[columns %in% colnames(idat)]]
    key = merge(key,tmp,all=T)
  }
  key = key[-1,] # clear holder


  episodes = matrix(unlist(strsplit(suspects$episodal_match,split = "_")),ncol=2,byrow = T)
  flagged_entries = list()
  for(s in 1:nrow(suspects)){
    event_info = key[key$dataset == suspects$dataset[s] & key$obs.count == suspects$event[s],]
    episode_info = key[key$dataset == episodes[s,1] & key$obs.count == episodes[s,2],]
    flagged_entries = c(flagged_entries,list(list("Flagged Event Information"=event_info,
                                                  "Flagged Episode Information"=episode_info)))
  }

  if(is.null((confirmed_matches))){
    if(length(flagged_entries)==1){
      message = paste0("\nNote:\n",length(flagged_entries), " entry flagged as an event-to-episode match. List generated for user evaluation of potential match.\n\n")
    }else{
      message = paste0("\nNote:\n",length(flagged_entries), " entries flagged as event-to-episode matches. List generated for user evaluation for all potential matches.\n\n")
    }
    cat(message)
    return(flagged_entries)
  }else{
    if(!is.logical(confirmed_matches)){stop("'confirmed_matches' argument must be a logical vector.")}
    if(length(confirmed_matches)>length(flagged_entries)){stop("Vector provided to the 'confirmed_matches' argument contains more entries than the number flagged matches")}
    if(length(confirmed_matches)<length(flagged_entries)){stop("Vector provided to the 'confirmed_matches' argument contains less entries than the number flagged matches")}

    keep = flagged_entries[confirmed_matches]
    unique_entries = meltt.data(object,columns=orig_columns)
    for(k in seq_along(keep)){
      remove = keep[[k]][[2]][,c("data.source","obs.count")]
      unique_entries = unique_entries[unique_entries$dataset != remove[,1] & unique_entries$event != remove[,2],]
    }
    cat("All confirmed event-to-episode duplicates have been removed.\n\n")
    return(unique_entries)
  }

}
