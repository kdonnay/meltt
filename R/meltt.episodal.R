meltt.episodal <- function(data,indexing,priormatches,twindow,spatwindow,smartmatch,certainty,k,secondary,partial,averaging,weight){
  
  # SORT data by timestamp and subset
  data <- data[order(data$date),] 
  row.names(data) <- NULL
  data_event <- subset(data,data$date==data$enddate)
  data_episode <- subset(data,data$date!=data$enddate)

  # FIRST, event-to-event matching
  if (nrow(data_event)>0){
    output <- meltt.match(data=data_event,twindow,spatwindow,smartmatch,certainty,k,secondary,partial,weight,episodal = 0)
    out_event <- meltt.disambiguate(data = data_event,match_output = output,indexing = indexing,priormatches = priormatches[[1]],averaging = averaging)
  }else{ # If empty, generate placeholders
    data_empty <- data.frame(matrix(0,nrow=0,ncol=ncol(data)))
    names(data_empty) <- names(data)
    match_empty <- data.frame(matrix(0,nrow=0,ncol=4))
    names(match_empty) <- c('data1','event1','data2','event2')
    contenders_empty <- data.frame(matrix(0,nrow=0,ncol=12))
    names(contenders_empty) <- c('dataset','event','bestmatch_data','bestmatch_event','bestmatch_score',
                                 'runnerUp1_data','runnerUp1_event','runnerUp1_score','runnerUp2_data',
                                 'runnerUp2_event','runnerUp2_score','events_matched')
    out_event <- list('data' = data_empty, 'matched' = match_empty,'contenders' = contenders_empty)
  }

  # THEN, episode-to-episode matching
  if (nrow(data_episode)>0 & length(unique(data_episode$dataset))>1){
    output <- meltt.match(data=data_episode,twindow,spatwindow,smartmatch,certainty,k,secondary,partial,weight,episodal = 0)
    out_episode <- meltt.disambiguate(data = data_episode,match_output = output,indexing = indexing,priormatches = priormatches[[3]],averaging = averaging)
  }else{
    data_empty <- data.frame(matrix(0,nrow=0,ncol=ncol(data)))
    if (nrow(data_episode)>0 & length(unique(data_episode$dataset))==1){
      data_empty <- data_episode
    }
    names(data_empty) <- names(data)
    match_empty <- data.frame(matrix(0,nrow=0,ncol=4))
    names(match_empty) <- c('data1','event1','data2','event2')
    contenders_empty <- data.frame(matrix(0,nrow=0,ncol=12))
    names(contenders_empty) <- c('dataset','event','bestmatch_data','bestmatch_event','bestmatch_score',
                                 'runnerUp1_data','runnerUp1_event','runnerUp1_score','runnerUp2_data',
                                 'runnerUp2_event','runnerUp2_score','events_matched')
    out_episode <- list('data' = data_empty, 'matched' = match_empty,'contenders' = contenders_empty)
  }
  # CONSOLIDATE matched data
  out <- list('data' = rbind(out_event$data,out_episode$data),
              'event_matched' = out_event$matched,
              'event_contenders' = out_event$contenders,
              'episode_matched' = out_episode$matched,
              'episode_contenders' = out_episode$contenders)

  # LAST, episode-to-event matching
  # 1) episodes from data 1 with events from data 2
  epsds1 = subset(out$data,out$data$date!=out$data$enddate & out$data$dataset==1)
  evnts2 = subset(out$data,out$data$date==out$data$enddate & out$data$dataset==2)
  data_12 <- rbind(epsds1,evnts2)
  if (nrow(epsds1)>0 & nrow(evnts2)>0){
    out_12 <- meltt.match(data=data_12,twindow,spatwindow,smartmatch,certainty,k,secondary,partial,weight,episodal = 1)
  }else{
    match_empty <- data.frame(matrix(0,nrow=0,ncol=4))
    names(match_empty) <- c('data1','event1','data2','event2')
    selected_empty <- data.frame(matrix(0,nrow=0,ncol=12))
    names(selected_empty) <- c('dataset','event','bestmatch_data','bestmatch_event','bestmatch_score',
                               'runnerUp1_data','runnerUp1_event','runnerUp1_score','runnerUp2_data',
                               'runnerUp2_event','runnerUp2_score','events_matched')
    out_12 <- list('matches' = match_empty, 'selected_matches' = selected_empty)
  }

  # 2) episodes from data 2 with events from data 1
  evnts1  = subset(out$data,out$data$date==out$data$enddate & out$data$dataset==1)
  epsds2 = subset(out$data,out$data$date!=out$data$enddate & out$data$dataset==2)
  data_21 <- rbind(epsds2,evnts1)
  # invert dataset labels for proper ordering of the analysis in meltt.match!
  dataset_index <- data_21$dataset
  data_21$dataset[dataset_index==2] <- 1
  data_21$dataset[dataset_index==1] <- 2
  if (nrow(epsds2)>0 & nrow(evnts1)>0){
    out_21 <- meltt.match(data=data_21,twindow,spatwindow,smartmatch,certainty,k,secondary,partial,weight,episodal = 1)
    # re-invert dataset labels
    if (nrow(out_21$matches)>0){
      out_21$matches[,c(1,3)] <- t(sapply(1:nrow(out_21$matches), function(x) out_21$matches[x,c(1,3)]<-c(2,1)))
      out_21$selected_matches[,c(1,3)] <- t(sapply(1:nrow(out_21$selected_matches), function(x) out_21$selected_matches[x,c(1,3)]<-c(2,1)))
    }
  }else{
    match_empty <- data.frame(matrix(0,nrow=0,ncol=4))
    names(match_empty) <- c('data1','event1','data2','event2')
    selected_empty <- data.frame(matrix(0,nrow=0,ncol=12))
    names(selected_empty) <-  c('dataset','event','bestmatch_data','bestmatch_event','bestmatch_score',
                                'runnerUp1_data','runnerUp1_event','runnerUp1_score','runnerUp2_data',
                                'runnerUp2_event','runnerUp2_score','events_matched')
    out_21 <- list('matches' = match_empty, 'selected_matches' = selected_empty)
  }

  # MARK all events that have episodal matches
  if (!is.element("episodal_match",names(out$data))){
    out$data$episodal_match <- ""
  }
  if (nrow(out_12$selected_matches)+nrow(out_21$selected_matches)>0){
    all_matches <- rbind(out_12$selected_matches[,1:4],out_21$selected_matches[,1:4])
    for (event in 1:nrow(all_matches)){
      ind_vec <- 1:nrow(out$data)
      ind <- ind_vec[out$data[,1]==all_matches[event,3] & out$data[,2]==all_matches[event,4]]
      if (all(out$data$episodal_match[ind]=="")){
        out$data$episodal_match[ind] <- paste0(unlist(indexing[[all_matches[event,1]]][all_matches[event,2],1]),"_",unlist(indexing[[all_matches[event,1]]][all_matches[event,2],2]))
      }else{
        out$data$episodal_match[ind] <- paste0(out$data$episodal_match[ind],', ',unlist(indexing[[all_matches[event,1]]][all_matches[event,2],1]),'_',unlist(indexing[[all_matches[event,1]]][all_matches[event,2],2]))
      }
    }
  }

  return(out)
}
