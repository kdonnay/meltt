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
  key$match_type = c(rep("event_to_event",nrow(event_to_event)),
                     rep("episode_to_episode",nrow(episode_to_episode)))
  
  # If matches are recorded that aren't real matches reduce set 
  determine = !apply(key,1,function(x){all(as.numeric(x[-1*c(1,2,length(x))])==0)})
  key = key[determine,] # remove the non-matches (i.e. those cases where there is no accommpanying event to match to)
  
  # Combine into specific key elements
  data_key = key[,seq_along(key) %% 2 != 0];data_key = data_key[,colnames(data_key)!="match_type"]
  obs_key = key[,seq_along(key) %% 2 == 0]
  input_data = object$inputData
  
  # Reconstituted Key (accounting for misalignment in the key log for data columns)
  key2 = key[,colnames(key)!="match_type"]
  for(i in seq(1,ncol(key2),2)){
    sub = key2[,c(i,i+1)]
    expansion=c()
    for(c in unique(sub[,1])){
      tmp = sub[sub[,1]==c,]
      colnames(tmp) = paste0(c("data","event"),c)
      expansion = rbind.fill(expansion,tmp)
    }
    if(i==1){
      key3 = expansion
    }else{
      key3 = cbind(key3,expansion)
    }
  }
  recon_key = key3[,!colnames(key3) %in% c("data0","event0")]
  drop = !apply(recon_key,1,function(x){sum(!is.na(x)) <= 2}) # Drop empty match-ups
  recon_key=recon_key[drop,]
  recon_key[is.na(recon_key)] = 0
  recon_key = recon_key[!apply(recon_key,1,function(x) all(x == 0)),] # Remove if any "all zeros" rows exist
  

  # Locate relevant columns, rename, and bind
  for(d in ncol(data_key):1){
    consider = input_data[[d]]
    consider = consider[consider$obs.count %in% obs_key[data_key==d],]
    consider2 = consider[,colnames(consider) %in% columns]
    colnames(consider2)[!colnames(consider2) %in% c("dataset","obs.count")] = paste(object$inputDataNames[d],colnames(consider2)[!colnames(consider2) %in% c("dataset","obs.count")],sep = "_")
    if(d==ncol(data_key)){
      out = merge(recon_key,consider2,
                  by.x=c(paste0("data",d),paste0("event",d)),
                  by.y=c("dataset","obs.count"),all.x=T)
    }else{
      out = merge(out,consider2,
                  by.x=c(paste0("data",d),paste0("event",d)),
                  by.y=c("dataset","obs.count"),all.x=T)
    }
  }
  # Generate Unique IDs
  .ind = c();for( c in data_key){.ind = c(.ind,c)}
  viable_options = unique(.ind[.ind>0])
  colnames(out)[colnames(out) %in% colnames(data_key)] = paste0(object$inputDataNames[viable_options],"_dataID")
  colnames(out)[colnames(out) %in% colnames(obs_key)] = paste0(object$inputDataNames[viable_options],"_eventID")
  return(out)
}
