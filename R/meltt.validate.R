meltt.validate = function(
  object=NULL,# Meltt object
  description.vars = NULL, # Varibles to consider in the description; if none are provided, taxonomy levels are used. 
  sample_prop = .1, # the proportion of matches sampled (which determines the size of the control group); minimum bound of .01% is placed on this
  within_window = T, # generate entries within the meltt integration s/t window
  spatial_window = NULL, # if within_window==F, set new s window
  temporal_window = NULL, # if within_window==F, set new t window
  reset = F # If T, the validation step will be reset and a new validation sample frame will be produced.
){
  
  obj_name = deparse(substitute(object))
  
  # CHECKS ------------------------------------------------------------------
  
  if(!is.meltt(object)){
    stop("Object is not of class meltt! Use meltt() to integrate data prior to validating.")
  }
  if(within_window==F & (is.null(spatial_window) | is.null(temporal_window))){
    stop("'within_window' has been set to false, user must provide a new temporal and spatial window from which to draw control group.")
  }
  if(sample_prop > 1 | sample_prop < 0.01){
    stop("`sample_prop` exceeds relevant bounds. Set argument to any numeric value existing between .01 and 1")
  }
  
  # BULID VALIDATION SET (if need be) ------------------------------------------------------------------
  if(!any(names(object) == "validation") | reset){ # Generate Validation Set if one does not already exist
  
    # GENERATE SAMPLES --------------------------------------------------------
    
    
    # Generates two "universe of the data": a matching set containing pairs of all
    # events that matched; and a "control" made up of a 50% mixture of match to
    # unique and unique-unique. 
    
    
    # GENERATE MATCH PAIRINGS (M-M) -------------------------------------------
    matches = meltt.duplicates(object)
    matches = matches[,grepl("dataID|eventID",colnames(matches))]
    cols = (1:ncol(matches))[1:ncol(matches) %% 2 == 1]
    match_id = matrix(nrow=nrow(matches),ncol=length(cols))
    for (c in 1:length(cols)) {
      matches[,cols[c]] = object$inputDataNames[c]
      match_id[,c] = paste0(matches[,cols[c]],"-",matches[,cols[c]+1])
    }
    # Edit out fillers
    blacklist = c(paste0(object$inputDataNames,"-0"),
                  paste0(object$inputDataNames,"-NA"))
    match_id[match_id %in% blacklist] = NA
    
    flagged_as_matches = c(match_id)[!is.na(c(match_id))] # Flag relevant matches...
    
    # generate pairings
    m_pairs = apply(match_id,1,function(x){
      alts = x[!is.na(x)]
      N = length(alts)
      out = sapply(2:N,function(x){
        c(alts[1],alts[x])
      })
      t(out)
    })
    
    # Generate population...
    if(is.list(m_pairs)){
      match_pop = ldply(m_pairs)
    } else{
      match_pop = as.data.frame(t(m_pairs))
    }
    colnames(match_pop) = c("uid1","uid2")
    match_pop$uid1 = as.character(match_pop$uid1)
    match_pop$uid2 = as.character(match_pop$uid2)
    
    
    # GENERATE CONTROL PAIRINGS (M-U,U-M,U-U) ---------------------------------
    
    # (1) generate composition of all input data frames.
    for(i in seq_along(object$inputData)){ # Gather input data into one frame
      if(i==1){all_input_dat = c() }
      tmp = object$inputData[[i]]
      colnames(tmp)[colnames(tmp)=='obs.count'] = 'event'
      all_input_dat = rbind.fill(tmp,all_input_dat)
    }
    all_input_dat$uid = paste(object$inputDataNames[all_input_dat$dataset],
                              all_input_dat$event,sep="-")
    
    # (2) subset to index proximate events
    if(within_window){ # If using the same proximity window as meltt
      t = object$parameters$twindow
      s = object$parameters$spatwindow
      D = data.matrix(all_input_dat[,c("dataset","date","latitude","longitude")])
      index = proximity(D,t = t,s = s)
    } else{ # If the user defines the proximity window
      t = temporal_window
      s = spatial_window
      D = data.matrix(all_input_dat[,c("dataset","date","latitude","longitude")])
      index = proximity(D,t = t,s = s)
    }
    
    # (3) locate the different populations (matched pairs, mixed pairs, unique pairs)
    exp_index = data.frame(uid1 = all_input_dat[index[,1],"uid"],uid2 = all_input_dat[index[,2],"uid"],
                           stringsAsFactors = F)
    exp_index$uid1_M = as.numeric(exp_index$uid1 %in% flagged_as_matches)
    exp_index$uid2_M = as.numeric(exp_index$uid2 %in% flagged_as_matches)
    exp_index = exp_index[!(exp_index$uid1_M == 1 & exp_index$uid2_M==1),] # drop matches
    mixed_pop = exp_index[(exp_index$uid1_M == 1 | exp_index$uid2_M==1),c(1,2)] 
    unique_pop = exp_index[(exp_index$uid1_M == 0 & exp_index$uid2_M==0),c(1,2)] # drop matches
    
    
    
    # RANDOMLY SAMPLE ---------------------------------------------------------
    match_sample = sample_frac(match_pop,sample_prop,replace = F)
    if( nrow(match_sample)< 1 ){ match_sample = sample_n(match_pop,1) } # in case sample is low
    retrieve_this_N = nrow(match_sample)
    mixed_sample = sample_n(mixed_pop,retrieve_this_N/2,replace = F)
    if( nrow(mixed_sample)< 1 ){ mixed_sample = sample_n(mixed_pop,1) } # in case sample is low
    unique_sample = sample_n(unique_pop,retrieve_this_N/2,replace = F)
    if( nrow(unique_sample)< 1 ){ unique_sample = sample_n(unique_pop,1) }
    
    # samples are proximate 50% from the mixes, 50% from uniques. Maybe off if
    # slightly from N of match if retrieve_this_N is odd.
    
    # Denote what is what
    match_sample$match = 1
    mixed_sample$match = 0
    unique_sample$match = 0
    
    
    # BUILD VALIDATION SET ----------------------------------------------------
    all_samp_entries = unique(
      c(
        c(match_sample$uid1,match_sample$uid2),
        c(mixed_sample$uid1,mixed_sample$uid2),
        c(unique_sample$uid1,unique_sample$uid2)
      )
    )
    
    # Gather descriptions and format in HTML 
    if(is.null(description.vars)){ # If no, description variables are offered, taxonomy info is used.
      descr_elements = all_input_dat[all_input_dat$uid %in% all_samp_entries,c("uid",object$taxonomy$taxonomy_names)]
      formatted = apply(descr_elements,1,function(x){
        x = iconv(x, "latin1", "ASCII", sub="") # Remove any potential encoding issues
        paste0(paste(paste0("<b><i>",names(x[-1]),"</i></b>"),x[-1],sep=": "),collapse = "<br/><br/>")
        # paste0(paste(names(x[-1]),x[-1],sep=": "),collapse = "\n\n")
      })
      descr = data.frame(uid=descr_elements$uid,descr=formatted,stringsAsFactors = F)
    }else{ # Use the columns the user provided
      descr_elements = all_input_dat[all_input_dat$uid %in% all_samp_entries,c("uid",description.vars)]
      formatted = apply(descr_elements,1,function(x){
        x = iconv(x, "latin1", "ASCII", sub="") # Remove any potential encoding issues
        paste0(paste(paste0("<b><i>",names(x[-1]),"</i></b>"),x[-1],sep=": "),collapse = "<br/><br/>")
        # paste0(paste(names(x[-1]),x[-1],sep=": "),collapse = "\n\n")
       })
      descr = data.frame(uid=descr_elements$uid,descr=formatted,stringsAsFactors = F)
    }
    
    # Build validation set
    validation_set = rbind(rbind(match_sample,mixed_sample),unique_sample)
    row.names(validation_set) = NULL
    validation_set = merge(validation_set,descr,by.x="uid1",by.y="uid",all.x=T)
    colnames(validation_set)[4] = "descr1"
    validation_set = merge(validation_set,descr,by.x="uid2",by.y="uid",all.x=T)
    colnames(validation_set)[5] = "descr2"
    validation_set$are_match = NA # the variable the coder codes when validating
    validation_set$timestamp = NA # time stamp to track when inputs are entered
    
    # Finally, scramble the sample 
    validation_set = sample_frac(validation_set,1)
    row.names(validation_set) = NULL
    
    
    # Save Validation set -----------------------------------------------------
    object$validation <- list(
      params = list(temporal_assessment_window = t,
                    spatial_assessment_window = s,
                    sample_proportion = sample_prop,
                    description_variables = ifelse(is.null(description.vars),
                                                   paste0(object$taxonomy$taxonomy_names,collapse=", "),
                                                   description.vars)),
      validation_set = validation_set,
      placeholder = 1,
      rates = NA
    )
    
    # End conditional ... that is, if this data already exists, no need to recreate it unless the user requests it
  } else{
    if(any(is.na(object$validation$validation_set))){
      cat("\n\n[!]\nAn existing validation composition  was detected. Set 'reset' argument to true if a new validation set should be generated, else prior set will be utilized.\n[!] \n\n")
    }
  } 
  
  

  # SHINY INTERFACE ---------------------------------------------------------
  
  # Activate Shiny application with recursive feedback. Saves directly to the
  # data in the meltt object (in case there is any crash). 
  
  # Est. Interface
  .ui <- fluidPage(
    
    fluidRow(
      column(12,align="center",
             h3("Do these two descriptions appear to be referencing the same event?")),
      column(width = 12, offset = 0, style='padding:20px;'),
      fluidRow(
        column(6,align='center',strong("Description 1")),
        column(6,align='center',strong("Description 2"))
      ),
      fluidRow(
        column(6,align="left",
               sidebarPanel(htmlOutput("descr1"),position = "center",width=12)
        ),
        
        column(6,align="left",
               sidebarPanel(htmlOutput("descr2"),position = "center",width=12)
        )
      ),
      column(width = 12, offset = 0, style='padding:40px;'),
      column(width = 12, align="center",htmlOutput("reviewed")),
      column(width = 12, offset = 0, style='padding:20px;'),
      fluidRow(
        column(12,align="center",
               column(6,align="right",
                      actionButton("back1",icon("chevron-left"),
                                   style="color: #fff; background-color:#c0c6d1;padding:20px; font-size:100%"),
                      actionButton("yes", "Yes",
                                   icon("thumbs-up"),
                                   style="color: #fff; background-color:#4ACC8B;padding:20px; font-size:100%")
               ),
               column(6,align="left",
                      actionButton("no", "No",
                                   icon("thumbs-down"),
                                   style="color: #fff; background-color:#F5585B;padding:20px; font-size:100%"),
                      actionButton("next1",icon("chevron-right"),
                                   style="color: #fff; background-color:#c0c6d1;padding:20px; font-size:100%")
               )
        ),
        column(width = 12, offset = 0, style='padding:40px;'),
        fluidRow(
          column(12,align='center',textOutput("progress"))
        ),
        column(width = 12, offset = 0, style='padding:40px;'),
        fluidRow(
          column(12,align='center',
                 actionButton("quit", "End Review", 
                              icon = icon("circle-o-notch"),
                              style="color: #ffffff; background-color:#444242;padding:20px; font-size:100%",
                              onclick = "setTimeout(function(){window.close();},500);")
          )
        )
        
      )
    )
  )
  
  # Est. server
  .server <- function(input, output){
    
    # Create Dynamic Var
    if(object$validation$placeholder>1){
      .n <- object$validation$placeholder
    }else{
      .n <- 1
    }
    makeReactiveBinding('.n')
    
    # Print Text Descriptions
    observe({
      output$descr1 <-   renderUI({
        HTML(object$validation$validation_set$descr1[.n])
      })
    })
    observe({
      output$descr2 <- renderUI({
        HTML(object$validation$validation_set$descr2[.n])
      })
    })
    observe({
      output$reviewed <-  renderText({
        if(!is.na(object$validation$validation_set$are_match[.n])){
          HTML("<font color='red' size='3'>Already Reviewed </font>")
        }else{
          HTML("  ")
        }
      })
      
    })
    observe({
      output$progress <- renderText({
        paste0("This is ",.n," of ", nrow(object$validation$validation_set),
               " entries being reviewed. Currently ",
               round(.n/nrow(object$validation$validation_set),3)*100,
               "% complete.")
      })
    })
    
    
    # Recursive buttons...
    observeEvent(input$yes, {
      object$validation$validation_set$are_match[.n] <<- 1
      object$validation$validation_set$timestamp[.n] <<- as.character(Sys.time())
    })
    observeEvent(input$no, {
      object$validation$validation_set$are_match[.n] <<- 0
      object$validation$validation_set$timestamp[.n] <<- as.character(Sys.time())
    })
    observeEvent(input$next1, {
      if(.n < nrow(object$validation$validation_set)){
        isolate({.n <<- .n + 1}) 
      }
    })
    observeEvent(input$back1, {
      if(.n>1){
        isolate({.n <<- .n - 1}) 
      }
    })
    
    # Clear Buttons
    observe({if(input$yes >= 1){reset("yes")}})
    observe({if(input$no >= 1){reset("no")}})
    observe({if(input$next1 >= 1){reset("next1")}})
    observe({if(input$back1 >= 1){reset("back1")}})
    
    
    # Quit App
    observeEvent(input$quit,{
      object$validation$placeholder <- .n
      cat("Input object has been overwritten, retaining current work.\n\n")
      stopApp(assign(as.character(obj_name),object,envir = globalenv()))
    })
    
  }
  
  
  if(any(is.na(object$validation$validation_set$are_match))){ 
    
    # If there are any values that have yet to be validated, Run app
    shinyApp(.ui, .server)
    
  } else{
    
    # CALCULATE ACCURACTY STATISTICS ------------------------------------------------
    reviewed = object$validation$validation_set
    
    TP  = sum(reviewed$match == 1 & reviewed$are_match == 1)/nrow(reviewed)
    FP  = sum(reviewed$match == 1 & reviewed$are_match == 0)/nrow(reviewed)
    TN  = sum(reviewed$match == 0 & reviewed$are_match == 0)/nrow(reviewed)
    FN  = sum(reviewed$match == 0 & reviewed$are_match == 1)/nrow(reviewed)
    TPR = TP + TN
    FPR = FP + FN
    
    
    # Save rates in object
    object$validation$rates <- list("True Positives"=round(TP,3),
                                    "False Positives"=round(FP,3),
                                    "True Negatives"=round(TN,3),
                                    "False Negatives"=round(FN,3))
    
    # Print accuracty output
    accuracy = matrix(round(c(TP,FP,TN,FN),3),2,2)
    colnames(accuracy) = c("Postives","Negatives")
    rownames(accuracy) = c("True","False")
    rates = matrix(paste0(round(c(TPR,FPR),3)*100,"%"),1,2)
    cat("\n\nMELTT Performance Accuracy of Integrated Sample \n",
        paste0(rep("---",12),collapse=""),"\n")
    print(accuracy)
    cat("",paste0(rep("---",12),collapse=""),"\n")
    cat("TPR: ",rates[1],"\n")
    cat("FPR: ",rates[2],"\n")
    cat("",paste0(rep("---",12),collapse=""),"\nA sample of",nrow(reviewed),"observations --",
        round(object$validation$params$sample_proportion*100,2)
        ,"% of the matched pairs with a control group of unmatched event pairs of equal size -- from the integrated data were manually reviewed.")
    assign(as.character(obj_name),object,envir = globalenv())
  }
}
