meltt <- function(...,taxonomies,twindow,spatwindow,smartmatch=TRUE,certainty=NA,partial=0,averaging=FALSE,weight=NA,silent=FALSE){
  
  # Mute interactive features, if silent = TRUE
  if(silent){
    cat <- function(...){}  
  }
  
  cat(' meltt: Matching Event Data by Location, Time and Type.\n Karsten Donnay and Eric Dunford, 2018\n\n NOTE: Depending on the size and number of datasets integration may take some time!\n\n\n ')
  call <- match.call()
  if (!silent){
    print(call)
  }
  
  # Key Input Information
  datasets <- as.list(substitute(list(...)))[-1L]
  names(datasets) <- NULL
  dataset_number <- length(datasets)
  for(i in seq_along(datasets)){if(i==1){hh=c()};hh = c(hh,min(as.Date(as.data.frame(eval(datasets[[i]]))[,"date"])))}
  min_date <- min(hh) # locate global minimum date
  tax_names <- names(taxonomies)
  k <- length(taxonomies)
  secondary <- sapply(1:k,function(x) length(taxonomies[[x]])-2)

  # CHECK if input data is appropriately formatted
  cat('\n Checking meltt() arguments and inputs: ')
  missing_arguments <- c()
  warning_arguments <- c()
  terminate <- FALSE
  # Check: parse and check data inputs
  p <- lapply(datasets,class)!="name"
  if (sum(p) >= 1){
    missing_arguments <- append(missing_arguments,paste0('\n  ',datasets[p],' \n'))
    terminate <- TRUE
  } else{
    for (i in 1:length(datasets)){
      if (!"data.frame" %in% class(eval(datasets[[i]]))){
        missing_arguments <- append(missing_arguments,paste0('\n  ',datasets[[i]],' \n'))
      }
    }
  }
  if (length(datasets)==0){
    missing_arguments <- append(missing_arguments,'\n  data \n')
    terminate <- TRUE
  }
  if (dataset_number==1){
    missing_arguments <- append(missing_arguments,'\n  Only one dataset inputted \n')
    terminate <- TRUE
  }
  if (is.null(tax_names) | length(tax_names)==0){ # Taxonomy Check
    # Is there a taxonomy?
    missing_arguments <- append(missing_arguments,'\n  taxonomies \n')
    terminate <- TRUE
  } else{
    # Is the taxonomy a list
    if (!is.list(taxonomies)){
      missing_arguments <- append(missing_arguments,paste0('\n taxonomies have to be entered as a list \n'))
      terminate <- TRUE
    }
    # Does the taxonomy map onto the input data?
    for (sets in 1:dataset_number){
      if (length(names(taxonomies)) != sum(colnames(eval(datasets[[sets]])) %in% names(taxonomies))){
        missing_tax <- names(taxonomies)[!names(taxonomies) %in% colnames(eval(datasets[[sets]]))]
        missing_arguments <- append(missing_arguments,paste0('\n  ',missing_tax,' taxonomy not located as a variable in ',datasets[[sets]],' \n'))
        terminate <- TRUE
      }
    }
    # Ensure that the taxonomies follow strict naming conventions:
    for (tax in 1:length(names(taxonomies))){
      cond <- tolower(colnames(taxonomies[[tax]])[c(1,2)]) == c("data.source","base.categories")
      if (sum(cond) !=2 ){
        colnames(taxonomies[[tax]][,c(1,2)])[!cond]

        renam = which(!cond)
        if (renam == 1){
          comment1 <- paste0('\n  column 1 in ',names(taxonomies[tax])," taxonomy must be labeled as 'data.source' \n")
          missing_arguments <- append(missing_arguments,comment1)
          terminate <- TRUE

          dataset_names = strsplit(x = paste0(datasets,collapse=" "),split=" ")[[1]]
          if (!all(dataset_names %in% taxonomies[[tax]][,1])){
            comment2 <- paste0('\n  column 1 in ',names(taxonomies[tax])," data.source column in the taxonomy must be labeled the same as the data object of the input data. \n")
            missing_arguments <- append(missing_arguments,comment2)
            terminate <- TRUE
          }
        }
        if (renam == 2){
          missing_arguments <- append(missing_arguments,paste0('\n  column 2 in ',names(taxonomies[tax])," taxonomy must be labeled as 'base.categories' and contain original coding of the variables used to create the taxonomy. \n"))
          terminate <- TRUE
        }
      }
      # Ensure that input data and data.source columns correspond
      for (tax in 1:length(names(taxonomies))){
        if("data.source" %in% colnames(taxonomies[[tax]])){
          ds_named_in_tax = unique(taxonomies[[tax]]$data.source)
          for(d in 1:length(datasets)){
            is_there = as.character(datasets[[d]]) %in% ds_named_in_tax
            if(!is_there){
              missing_arguments <- append(missing_arguments,paste0('\n  dataset ',datasets[[d]],' is not named as a data.source in ',names(taxonomies[tax]),' \n'))
              terminate <- TRUE
            }
          }
        }
      }
      # Ensure that taxonomies progress from most granular to broadest k
      tlevels = apply(as.data.frame(taxonomies[[tax]][,c(1,2)*-1]),2,function(x) length(unique(x)))
      sorted = is.unsorted(rev(tlevels)) # Sorted.
      g_to_b =  tlevels[1] >= tlevels[length(tlevels)] # granular to broad
      if(!any(sorted | g_to_b)){
        missing_arguments <- append(missing_arguments,paste0('\n  column 2 in ',names(taxonomies[tax])," taxonomy must be ordered from most granular level to broadest level. Order is either reversed, or an error exists within the taxonomy.\n"))
        terminate <- TRUE
      }
    }
  }
  if (missing(twindow)){
    missing_arguments <- append(missing_arguments,'\n  twindow')
    terminate <- TRUE
  }
  if (missing(spatwindow)){
    missing_arguments <- append(missing_arguments,'\n  spatwindow')
    terminate <- TRUE
  }
  if (smartmatch==FALSE){
    if(any(is.na(certainty))){
      missing_arguments <- append(missing_arguments,'\n  certainty must be specified if "smartmatch=FALSE"')
      terminate <- TRUE
    }else{
      if (!is.numeric(certainty)){
        missing_arguments <- append(missing_arguments,'\n  certainty must be numeric')
        terminate <- TRUE
      }
      if (length(certainty)!=k){
        missing_arguments <- append(missing_arguments,'\n  certainty must be specified for each taxonomy')
        terminate <- TRUE
      }else if (any(certainty<1) | any(secondary-certainty<0)){
        missing_arguments <- append(missing_arguments,'\n  certainty (out of value range)')
        terminate <- TRUE
      }
    }
  }

  if(length(weight)>1){
    if (!is.numeric(weight)){
      missing_arguments <- append(missing_arguments,'\n  weight must be numeric')
      terminate <- TRUE
    }else if (sum(weight)!=length(secondary)){
      missing_arguments <- append(missing_arguments,'\n  weight not correctly normalized')
      terminate <- TRUE
    }
    if (length(weight)!=k){
      missing_arguments <- append(missing_arguments,'\n  weight must be specified for each taxonomy')
      terminate <- TRUE
    }
  }else{
    weight <- rep(1,k)
  }
  enddate_check <- FALSE
  for (dat in 1:length(datasets)){
    if (is.element('enddate',names(eval(datasets[[dat]])))){
      enddate_check <- TRUE
    }
  }
  for (dat in 1:length(datasets)){
    if (!is.element('date',names(eval(datasets[[dat]])))){
      missing_arguments <- append(missing_arguments,paste0('\n  data: date column(s) are missing in ',as.character(datasets[[dat]]),''))
      terminate <- TRUE
    }else{
      if(class(as.data.frame(eval(datasets[[dat]]))[,'date'])!="Date"){
        missing_arguments <- append(missing_arguments,
                                    paste0('\n  data: date column in ',
                                           as.character(datasets[[dat]]),
                                           " is not of class 'Date' or is not formatted as 'yyyy-mm-dd'"))
        terminate <- TRUE
      }
    }
    if (!is.element('enddate',names(eval(datasets[[dat]]))) & enddate_check){
      warning_arguments <- append(warning_arguments,paste0("\nOne or more of the input datasets contains episodal data but no 'enddate' varible was specified for dataset '",as.character(datasets[[dat]]),
                                                           "'. If an end date variable exists, please relabel as 'enddate'.\n"))
    }
    if (!is.element('latitude',names(eval(datasets[[dat]])))){
      missing_arguments <- append(missing_arguments,paste0('\n  data: latitude column is missing in ',as.character(datasets[[dat]]),''))
      terminate <- TRUE
    } else{
      if(class(as.data.frame(eval(datasets[[dat]]))[,'latitude'])!="numeric"){
        missing_arguments <- append(missing_arguments,paste0('\n  data: latitude column in ',as.character(datasets[[dat]]),
                                                             " is not class 'Numeric' \n"))
        terminate <- TRUE
      }
    }
    if (!is.element('longitude',names(eval(datasets[[dat]])))){
      missing_arguments <- append(missing_arguments,paste0('\n  data: longitude column is missing in ',as.character(datasets[[dat]]),''))
      terminate <- TRUE
    } else{
      if(class(as.data.frame(eval(datasets[[dat]]))[,'longitude'])!="numeric"){
        missing_arguments <- append(missing_arguments,paste0('\n  data: longitude column in ',as.character(datasets[[dat]]),
                                                             " is not class 'Numeric'"))
        terminate <- TRUE
      }
    }
  }
  if (terminate){ # Stop the function and print warnings
    missing_arguments <- append(unique(missing_arguments)," \n\n")
    message("The following required arguments of meltt() are MISSING or MIS-SPECIFIED:", missing_arguments)
    stop("meltt(...,taxonomies,twindow,spatwindow)) was not executed!", call.=FALSE)
  }else{
    cat('Done.\n')
  }
  if (!is.null(warning_arguments)){
    cat(paste0("\nPlease note the following:\n",paste0(warning_arguments,collapse="")))
  }

  # DATA Pre-Processing
  # - retain original data and ordering
  cat(' Preparing data for integration: ')
  data_list <- list()
  for(data_set in seq_along(datasets)){
    dat <- as.data.frame(eval(datasets[[data_set]]))
    dat$data.source <- as.character(datasets[[data_set]])
    dat$dataset <- match(as.character(datasets[[data_set]]),datasets)
    dat$obs.count <- 1:nrow(dat)
    if(any(colnames(dat)=="enddate")){dat[,"enddate"] <- as.Date(dat[,"enddate"])}else{dat[,"enddate"] <- as.Date(dat[,"date"])}
    data_list[[data_set]] <- dat
  }

  #FORMAT data to numerical matrix & STAMP and STORE input data.
  stamps <- c()
  tax_entries <- c()
  issue_messages <- c()
  for(d in seq_along(datasets)) {
    dd <- data_list[[d]]
    dd <- dd[order(dd$date),]
    rownames(dd) <- NULL
    std_cols <- c("date","enddate","latitude","longitude")
    combine <- data.frame(dataset=dd[,"dataset"],
                          event=dd[,"obs.count"],
                          date=as.numeric(dd[,"date"] - min_date),
                          enddate=as.numeric(dd[,"enddate"] - min_date),
                          latitude=dd[,"latitude"],
                          longitude=dd[,"longitude"])
    rownames(combine) <- 1:nrow(combine)
    tax.out <- meltt.taxonomy(dd,taxonomies)
    tax.vars <- tax.out$processed_taxonomies
    issue_messages <- c(issue_messages,tax.out$issue_messages) # store any error messages
    stamps <- rbind(stamps,combine) # retain entry geo/time/index
    tax_entries <- rbind(tax_entries,tax.vars) # retain tax
  }
  if(length(issue_messages) > 0){ # Taxonomy Check: stop if issue with taxonomy mapping detected
    taxonomy_stop_message <- paste0("\n\n",paste0(issue_messages,collapse=""),"Please ensure that each unique data entry in the input data contains a corresponding value in the base.category column for each input taxonomy.\n\n")
    cat(taxonomy_stop_message)
    stop("Stopped due to taxonomy error (see above report for detailed summary).")

  }

  numeric_tax <- apply(as.matrix(tax_entries),2,function(x) as.numeric(as.factor(x))) # convert taxonomy text to numeric
  names(data_list) <- datasets # record data names to original data
  data <- cbind(stamps,numeric_tax) # combine entry stamps with taxonomies
  
  cat('Done.\n')

  # RUN matching algorithm
  for (datst in 2:dataset_number){
    if (datst == 2){
      cat(' Integrating dataset 1 with dataset 2: ')
      dat <- subset(data,data$dataset==1)
      dat_new <- subset(data,data$dataset==2)
      # save old indices
      indexing <- list(dat[,1:2],dat_new[,1:2])
      # order data
      dat <- dat[order(dat$date),]
      rownames(dat) <- NULL
      dat_new <- dat_new[order(dat_new$date),]
      rownames(dat_new) <- NULL
      # generate new (time-ordered) indices
      dat[,1] <- 1
      dat[,2] <- 1:nrow(dat)
      dat_new[,1] <- 2
      dat_new[,2] <- 1:nrow(dat_new)
      # new joined data
      dat <- rbind(dat,dat_new)
      out <- meltt.episodal(dat,indexing,priormatches = c(),twindow,spatwindow,smartmatch,certainty,k,secondary,partial,averaging,weight,silent)
      if nrow(out$data) > 0{
        out$data[,1:2] <- data.frame(t(sapply(1:nrow(out$data),function(x) unlist(indexing[[out$data$dataset[x]]][out$data$event[x],])))) # restore correct indices in data
      }
      cat('Done.')
    }else{
      cat(paste0('\n Integrating merged data and dataset ',datst,': '))
      dat <- out$data
      past_event_contenders <- out$event_contenders
      past_episode_contenders <- out$episode_contenders
      dat_new <- subset(data,data$dataset==datst)
      # save old indices
      indexing <- list(dat[,1:2],dat_new[,1:2])
      # order data
      dat_new <- dat_new[order(dat_new$date),]
      rownames(dat_new) <- NULL
      if (is.element("episodal_match",names(out$data))){ dat_new$episodal_match <- "" }
      # generate new (time-ordered) indices
      dat[,1] <- 1
      dat[,2] <- 1:nrow(dat)
      dat_new[,1] <- 2
      dat_new[,2] <- 1:nrow(dat_new)
      # new joined data
      dat <- rbind(dat,dat_new)
      out <- meltt.episodal(dat,indexing,priormatches = list(out$event_matched,
                                                             out$event_contenders,
                                                             out$episode_matched,
                                                             out$episode_contenders),
                            twindow,spatwindow,smartmatch,certainty,k,secondary,partial,averaging,weight,silent)
      if nrow(out$data) > 0{
        out$data[,1:2] <- data.frame(t(sapply(1:nrow(out$data),function(x) unlist(indexing[[out$data$dataset[x]]][out$data$event[x],])))) # restore correct indices in data
      }

      # Bind past contenders with current
      out$event_contenders <- rbind(past_event_contenders,out$event_contenders)
      out$episode_contenders <- rbind(past_episode_contenders,out$episode_contenders)
      cat('Done.')
    }
    out$data <- out$data[order(out$data$date,out$data$dataset,out$data$event),]
    row.names(out$data) <- NULL
  }

  # Retain Processing features
  names(out)[1] <- "deduplicated_index" # Rename data feature
  out$complete_index <- data
  out <- out[c("complete_index","deduplicated_index","event_matched","event_contenders","episode_matched","episode_contenders")]

  if(ncol(out$event_matched) != ncol(out$episode_matched)){
    # If episode matched does not map onto event_matched (due to episodal data
    # existing in some but not all the input datasets), correct index in
    # episode_matched
    em <- out$episode_matched
    datindex <- unique(em[,grep("data",colnames(em))])
    for(i in 1:ncol(datindex)){
      if(i==1){corrected <- c()}
      corrected <- c(corrected,paste0(c("data","event"),c(datindex[1,i])))
    }
    colnames(em) <- corrected
    tmpentry <- out$event_matched[1,]
    tmpentry[1,] <- 0
    em_new <- rbind.fill(em,tmpentry)
    em_new[is.na(em_new)] <- 0
    em_new <- em_new[-nrow(em_new),]
    out$episode_matched <- em_new
  }

  # Retain initial input features
  tax_stats <- list(taxonomy_names=tax_names,N_taxonomies = k,
                    taxonomy_depths = secondary,input_taxonomies=taxonomies)
  params <- list(twindow=twindow,spatwindow=spatwindow,
                 smartmatch=smartmatch,certainty=certainty,
                 partial=partial,averaging=averaging,weight=weight)

  # PRODUCE master list containing all relevant output features.
  master.out <- list(processed = out,inputData = data_list,parameters=params,
                     inputDataNames = sapply(datasets, paste0, collapse=""),
                     taxonomy = tax_stats)

  class(master.out) <- "meltt"
  cat('\n Integration completed!')
  return(master.out)
}