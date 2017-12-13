meltt.match <- function(data,twindow,spatwindow,smartmatch,certainty,k,secondary,partial,weight,episodal){
  if (smartmatch==TRUE){
    certainty <- rep(0,k)
  }
  
  # SORT by timestamp and remove last columns, if necessary
  data <- data[order(data$date),] 
  row.names(data) <- NULL
  if (is.element("episodal_match",names(data))){
    data <- data[,1:(ncol(data)-1)]
  }
  # Read in the script
  # call the main "run" function with its input
  colnames <- colnames(data)
  match <- py_run_file(paste0(find.package("meltt"),"/python/match.py"))
  output_list <- match$run(data,colnames,twindow,spatwindow,smartmatch,k,secondary,certainty,partial,weight,episodal)
  
  # turn into data.frames
  if(length(unlist(output_list[1]))==0){
    output <- list(matches = data.frame(matrix(0, nrow=0, ncol=5, byrow=T)))
  }else{
    output <- list(matches = data.frame(matrix(unlist(output_list[1]), ncol=5, byrow=T)))
  }
  names(output$matches) <- c('data1','event1','data2','event2','score')
  if (episodal==0){
    if (length(unlist(output_list[2]))==0){
      output$selected_matches <- data.frame(matrix(0, nrow=0, ncol=12, byrow=T))
    }else{
      output$selected_matches <- data.frame(matrix(unlist(output_list[2]), ncol=12, byrow=T))
    }
    names(output$selected_matches) <- c('dataset','event','bestmatch_data','bestmatch_event','bestmatch_score',
                                        'runnerUp1_data','runnerUp1_event','runnerUp1_score','runnerUp2_data',
                                        'runnerUp2_event','runnerUp2_score','events_matched')
  }else{
    if (length(unlist(output_list[2]))==0){
      output$selected_matches <- data.frame(matrix(0, nrow=0, ncol=5, byrow=T))
    }else{
      output$selected_matches <- data.frame(matrix(unlist(output_list[2]), ncol=5, byrow=T))
    }
    names(output$selected_matches) <- c('data1','event1','data2','event2','score')
  }
  return(output)
}