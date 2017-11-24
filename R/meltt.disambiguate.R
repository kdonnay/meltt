meltt.disambiguate <- function(data,match_output,indexing,priormatches,averaging){
  # TRUNCATE to best match and RELABLE columns
  matches <- match_output$selected_matches[,1:4]
  names(matches) <- c('data1','event1','data2','event2')

  contenders = match_output$selected_matches # retain info on runners-up

  # DISAMBIGUATE data
  if (nrow(matches)>0){
    for (event in 1:nrow(matches)){
      # implement averaging here prior to deletion
      selector1 <- data[,1]==matches[event,1] & data[,2]==matches[event,2]
      selector2 <- data[,1]==matches[event,3] & data[,2]==matches[event,4]
      if (averaging){
        # startdate average
        data[selector1,3] <- round(mean(c(data[selector1,3],data[selector2,3])))
        # location average
        # lat
        data[selector1,4] <- mean(c(data[selector1,4],data[selector2,4]))
        # lon
        data[selector1,5] <- mean(c(data[selector1,5],data[selector2,5]))
      }
      # remove duplicates
      data[selector2,] <- -1000000
    }
    data <- data[data[,1]!=-1000000,]

    # RESTORE correct indices in matches
    matches[,1:4] <- data.frame(t(sapply(1:nrow(matches),function(x) c(unlist(indexing[[matches$data1[x]]][matches$event1[x],]),unlist(indexing[[matches$data2[x]]][matches$event2[x],])))))

    # RESTORE correct indices in contenders
    locs = !grepl("score",colnames(contenders)) # id relevant locations in frame
    locs[length(locs)] = F
    contenders[,locs] <- data.frame(t(sapply(1:nrow(contenders),function(x){
      a = unlist(indexing[[contenders$dataset[x]]][contenders$event[x],])
      b = unlist(indexing[[contenders$bestmatch_data[x]]][contenders$bestmatch_event[x],])
      if(contenders$runnerUp1_data[x]>0){
        c = unlist(indexing[[contenders$runnerUp1_data[x]]][contenders$runnerUp1_data[x],])
      } else{c = unlist(data.frame(dataset=0,event=0))}
      if(contenders$runnerUp2_data[x]>0){
        d = unlist(indexing[[contenders$runnerUp2_data[x]]][contenders$runnerUp2_data[x],])
      } else{d = unlist(data.frame(dataset=0,event=0))}
      c(a,b,c,d)
    })))
  }

  # IF not first step in iteration, generate summary of matches
  if (length(priormatches)>0){
    if (nrow(priormatches)>0){
      iter <- ncol(priormatches)/2
      matched <- priormatches
      matched[,ncol(priormatches)+1] <- 0
      matched[,ncol(priormatches)+2] <- 0
      names(matched) <- c(names(priormatches),paste0('data',iter+1),paste0('event',iter+1))
      cols <- seq(1,ncol(matched)-3,by=2)
      colms <- c(iter*2+1,iter*2+2)

      if(nrow(matches)>0){ # Conditional in case there are no matches
        # PARSE matches
        for (event in 1:nrow(matches)){
          if (any(matched[,cols] == matches[event,1] & matched[,cols+1] == matches[event,2])){
            for (columns in cols){
              if (any(matched[,columns] == matches[event,1] & matched[,columns+1] == matches[event,2])){
                matched[matched[,columns] == matches[event,1] & matched[,columns+1] == matches[event,2],colms] <- matches[event,3:4]
              }
            }
          }else{
            newentry <- rep(0,ncol(matched))
            newentry[(matches[event,1]-1)*2+1:2] <- c(matches[event,1],matches[event,2])
            newentry[(matches[event,3]-1)*2+1:2] <- c(matches[event,3],matches[event,4])
            matched <-rbind(matched,newentry)
          }
        }
      }
    }else{
      matched <- matches
    }
  }else{
    matched <- matches
  }

  # RETURN disambiguated data and match summary
  output <- list('data' = data, 'matched' = matched,"contenders" = contenders)

  return(output)
}
