meltt_validate = function(
  object,# Meltt object
  description.vars = NULL, # Varibles to consider in the description; if none are provided, taxonomy levels are used.
  sample_prop = .1, # the proportion of matches sampled (which determines the size of the control group); minimum bound of .01% is placed on this
  within_window = TRUE, # generate entries within the meltt integration s/t window
  spatial_window = NULL, # if within_window==F, set new s window
  temporal_window = NULL, # if within_window==F, set new t window
  reset = FALSE # If TRUE, the validation step will be reset and a new validation sample frame will be produced.
){
  UseMethod("meltt_validate")
}

# Variable declaration to satisfy CRAN check
utils::globalVariables(c('uid', 'm1', 'm2','cohort'))

meltt_validate.meltt = function(
  object,# Meltt object
  description.vars = NULL, # Varibles to consider in the description; if none are provided, taxonomy levels are used.
  sample_prop = .1, # the proportion of matches sampled (which determines the size of the control group); minimum bound of .01% is placed on this
  within_window = T, # generate entries within the meltt integration s/t window
  spatial_window = NULL, # if within_window==F, set new s window
  temporal_window = NULL, # if within_window==F, set new t window
  reset = FALSE # If T, the validation step will be reset and a new validation sample frame will be produced.
){

  # The "Choose from 3-options" version
  obj_name <- deparse(substitute(object))

  # CHECKS ------------------------------------------------------------------

  if(within_window==F & (is.null(spatial_window) | is.null(temporal_window))){
    stop("'within_window' has been set to FALSE, user must provide a new temporal and spatial window from which to draw control group.")
  }
  if(sample_prop > 1 | sample_prop < 0.001){
    stop("`sample_prop` exceeds relevant bounds. Set argument to any numeric value existing between .01 and 1")
  }

  # BULID VALIDATION SET (if need be) ------------------------------------------------------------------
  if(!any(names(object) == "validation") | reset){ # Generate Validation Set if one does not already exist

    # Specify Matching events
    matches <- meltt_duplicates(object)
    matches <- matches[,grepl("dataset|event",colnames(matches))]
    cols <- (1:ncol(matches))[1:ncol(matches) %% 2 == 1]
    match_id <- matrix(nrow=nrow(matches),ncol=length(cols))
    for (c in 1:length(cols)) {
      matches[,cols[c]] <- object$inputDataNames[c]
      match_id[,c] <- paste0(matches[,cols[c]],"-",matches[,cols[c]+1])
    }
    # Edit out fillers
    blacklist <- c(paste0(object$inputDataNames,"-0"),
                  paste0(object$inputDataNames,"-NA"))
    match_id[match_id %in% blacklist] = NA
    M <- data.frame(match_id,stringsAsFactors = F);M$match_id = 1:nrow(M)
    M2 <- gather(M,match,uid,-match_id)
    M2 <- arrange(drop_na(select(M2,uid,match_id)),match_id)

    # GENERATE input data frame from input data
    for(i in seq_along(object$inputData)){ # Gather input data into one frame
      if(i==1){all_input_dat = c() }
      tmp <- object$inputData[[i]]
      colnames(tmp)[colnames(tmp)=="obs.count"] <- "event"
      tmp <- tmp[order(tmp$date),]
      all_input_dat <- rbind.fill(tmp,all_input_dat)
    }
    all_input_dat$uid <- paste(object$inputDataNames[all_input_dat$dataset],
                              all_input_dat$event,sep="-")

    # Map match ids onto the input data frame
    all_input_dat <- merge(all_input_dat,M2,by="uid",all.x=T)

    # Order input dataframe so nearby cohorts reflect proximity
    all_input_dat <- all_input_dat[order(all_input_dat$date),]


    # LOCATE proximate events
    stay_here_and_build_index_of_prox_entries = T
    report_window_increased = F; second_time_around = T
    while(stay_here_and_build_index_of_prox_entries){
      if(within_window){ # If using the same proximity window as meltt
        t <- object$parameters$twindow
        s <- object$parameters$spatwindow
        D <- data.matrix(all_input_dat[,c("dataset","date","latitude","longitude")])
        index <- proximity(D,t = t,s = s)
      } else{ # If the user defines the proximity window
        t <- temporal_window
        s <- spatial_window
        D <- data.matrix(all_input_dat[,c("dataset","date","latitude","longitude")])
        index <- proximity(D,t = t,s = s)
      }



      # Produce set of "proximate" entries
      exp_index <- data.frame(uid1 = all_input_dat[index[,1],"uid"],
                              uid2 = all_input_dat[index[,2],"uid"],
                              m1 = all_input_dat[index[,1],"match_id"],
                              m2 = all_input_dat[index[,2],"match_id"],
                              cohort = index[-1,3],
                              stringsAsFactors = F)


      # Determine which of those proximate entries are matches
      exp_index$match <- as.numeric((exp_index$m1 == exp_index$m2) & (!is.na(exp_index$m1) & !is.na(exp_index$m2)))

      # Check that there a are sufficient unique (non-matching entries) --
      # required for the control set.
      if(mean(exp_index$match==0) >= .4){ # If sufficient, move on
        stay_here_and_build_index_of_prox_entries = F
      }else{
        within_window = F # Adjust window
        if(second_time_around){ # Set the initial conditions if a expansion is required
          temporal_window = t
          spatial_window = s
          second_time_around = F
        }
        temporal_window = temporal_window + 1 # increase time window by 1 day
        spatial_window = spatial_window + 5 # increase spatial extent by 5km
        report_window_increased = T
      }
    }
    if(report_window_increased){
      warning("\nThere was an insufficient number of unique events to build a control set from within the current spatio-temporal window.",
          " The extent of the window was expanded until a sufficient number of non-matching events were located.\n")
    }


    # GENERATE matches/control samples, where control is drawn from proximate events -------------------------
    match_samp <- sample_frac(data.frame(match_id=unique(exp_index$m1[exp_index$match == 1])),sample_prop)
    if( nrow(match_samp)< 1 ){ match_samp <- sample_n(data.frame(match_id=unique(exp_index$m1[exp_index$match == 1])),1) } # in cases where sample is low

    cat('\nGenerating Validation Set ... \n')
    v_set <- c()
    pb <- progress_estimated(nrow(match_samp))
    for(s in 1:nrow(match_samp)){
      draw_set <- exp_index[(exp_index$m1==match_samp$match_id[s] | exp_index$m2==match_samp$match_id[s]) & (!is.na(exp_index$m1) & !is.na(exp_index$m2)),]
      orig_set <- function(x) gsub("[-]\\d+","",x)
      c_range <- draw_set$cohort[draw_set$match==1][1]

      go <- i <- T
      while(go){ # Adaptive code chunk that incrementally builds a "as close as possible" control group
        if(i > 1){
          near_by_entries <- exp_index[exp_index$cohort >= c_range-i & exp_index$cohort <= c_range+i & exp_index$match!=1,]
          draw_set <- unique(rbind(draw_set,near_by_entries))
        }
        display_entry <- draw_set$uid1[draw_set$match==1][1]
        matching_entry <- draw_set$uid2[draw_set$match==1][1]
        control_entries <- c(draw_set$uid1[draw_set$match==0 & (draw_set$m1!=match_samp$match_id[s] | is.na(draw_set$m1))], # generate control sample
                             draw_set$uid2[draw_set$match==0 & draw_set$m2!=match_samp$match_id[s] | is.na(draw_set$m2)])
        control_entries <- control_entries[!control_entries %in% c(display_entry,matching_entry)] # not the display/matching entry
        control_entries <- unique(control_entries[orig_set(control_entries) != orig_set(display_entry)]) # from a different source than the display entry
        if(length(control_entries)>2){
          go <- F
          control_sample <- sample(control_entries,2,replace=F)
          entry <- data.frame(display_entry,matching_entry,control_entry1=control_sample[1],
                             control_entry2=control_sample[2],stringsAsFactors = F)
        }else{i = i + 1}
      }

      v_set <- rbind(v_set,entry)
      pb$tick()$print()
    }


    # BUILD VALIDATION SET ---------------

    # If no description variables have been specified...
    if(is.null(description.vars)){description.vars = object$taxonomy$taxonomy_names}

    # Double check that all the description.vars exist
    if(!all(description.vars %in% names(all_input_dat))){
      cat("\nSome description.vars do not exist. Using taxonomy elements as descriptions instead.\n")
      description.vars = object$taxonomy$taxonomy_names
    }

    # Build entry info
    entries_info <-
      apply(v_set,1,function(x){
        y = c()
        for(i in x){
          tmp <- all_input_dat[all_input_dat$uid %in% i,c("uid",description.vars)]
          y <- rbind(y,tmp)
        }
        cbind(type=names(x),y)
      })
    entries_info <- as.tibble(ldply(entries_info))

    formatted <- apply(entries_info[,c(1:3)*-1],1,function(x){
      x = iconv(x, "latin1", "ASCII", sub="") # Remove any potential encoding issues
      paste0(paste(paste0("<b><i>",names(x),"</i></b>"),x,sep=": "),collapse = "<br/><br/>")
      # paste0(paste(names(x),x,sep=": "),collapse = "\n\n")
    })
    id = rep(1:(nrow(entries_info)),4)
    validation_set <- data.frame(val_id = id[order(id)],
                                 uid=entries_info$uid,
                                 type=as.character(entries_info$type),
                                 descr=formatted,
                                 coding=NA,
                                 coding_txt ="",
                                 stringsAsFactors = F)

    # Shuffle the validation entries up (so matching entry is in a different location each time)
    validation_set2=c()
    for(v in unique(validation_set$val_id)){
      ss <- validation_set[validation_set$val_id==v,]
      validation_set2 <- rbind(validation_set2,ss[c(1,sample(2:4)),])
    }


    cat('\nValidation Set Generated!\n')
    # Save Validation set -----------------------------------------------------
    object$validation <- list(
      params = list(temporal_assessment_window = t,
                    spatial_assessment_window = s,
                    sample_proportion = sample_prop,
                    description_variables = paste0(description.vars,collapse=", ")),
      validation_set = validation_set2,
      placeholder = 1,
      rates = NA
    )

    # End conditional ... that is, if this data already exists, no need to recreate it unless the user requests it
  } else{
    if(any(is.na(object$validation$validation_set))){
      message("\n\nAn existing validation composition  was detected. Set 'reset' argument to true if a new validation set should be generated, else prior set will be utilized.\n")
    }
  }


  # SHINY INTERFACE ---------------------------------------------------------

  # Activate Shiny application with recursive feedback. Saves directly to the
  # data in the meltt object (in case there is any crash).

  # Est. Interface
  .ui <- fluidPage(

    fluidRow(
      column(12,align="center",
             h3("Which of these three entries best matches the main entry?")),
      column(width = 12, offset = 0, style='padding:10px;')),

    # Main-Entry Titles
    fluidRow(column(12,align='center',strong("Main Entry")),
             column(12,align='center',
                    sidebarPanel(htmlOutput("descr_main"),position = "center",width=12)
             )),

    # Report Regarding Choice...
    fluidRow(
      column(width = 12, align="center",htmlOutput("status_1"))
    ),

    # Buttons to vote on Choice...
    fluidRow(
      column(width = 12, offset = 0, style='padding:20px;'),
      column(4,align="center",
             actionButton("choice1", "Entry A",style="color: #fff; background-color:#b3b3b5;padding:20px; font-size:18px; width: 100px")
      ),
      column(4,align="center",
             actionButton("choice2", "Entry B",style="color: #fff; background-color:#b3b3b5;padding:20px; font-size:18px; width: 100px")
      ),

      column(4,align="center",
             actionButton("choice3", "Entry C",style="color: #fff; background-color:#b3b3b5;padding:20px; font-size:18px; width: 100px")
      ),
      column(width = 12, offset = 0, style='padding:5px;')
    ),

    # Descriptions for the three options being drawn
    fluidRow(
      column(4,align="left",
             sidebarPanel(htmlOutput("descr1"),position = "center",width=12)
      ),
      column(4,align="left",
             sidebarPanel(htmlOutput("descr2"),position = "center",width=12)
      ),
      column(4,align="left",
             sidebarPanel(htmlOutput("descr3"),position = "center",width=12)
      )
    ),

    fluidRow(
      column(12,align="center",
             actionButton("back1",icon("chevron-left"),
                          style="color: #fff; background-color:#c0c6d1;padding:20px; font-size:100%"),
             actionButton("next1",icon("chevron-right"),
                          style="color: #fff; background-color:#c0c6d1;padding:20px; font-size:100%")
      ),

      # Progress Report
      column(width = 12, offset = 0, style='padding:10px;'),
      fluidRow(column(12,align='center',textOutput("progress")),
               column(width = 12, offset = 0, style='padding:10px;')),
      column(width = 12, offset = 0, style='padding:10px;'),
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
      output$descr_main <-   renderUI({
        HTML(object$validation$validation_set$descr[object$validation$validation_set$val_id==.n][1])
      })
    })
    observe({
      output$descr1 <-   renderUI({
        HTML(object$validation$validation_set$descr[object$validation$validation_set$val_id==.n][2])
      })
    })
    observe({
      output$descr2 <- renderUI({
        HTML(object$validation$validation_set$descr[object$validation$validation_set$val_id==.n][3])
      })
    })
    observe({
      output$descr3 <- renderUI({
        HTML(object$validation$validation_set$descr[object$validation$validation_set$val_id==.n][4])
      })
    })

    # Update progress
    observe({
      output$progress <- renderText({
        paste0("This is ",.n," of ", max(object$validation$validation_set$val_id),
               " entries being reviewed. Currently ",
               round(.n/max(object$validation$validation_set$val_id),3)*100,
               "% complete.")
      })
    })

    # Recursively change selected output when no option has been selected yet (i.e. new entries)
    observeEvent(.n,{
      output$status_1 <-renderText({
        if(all(object$validation$validation_set$coding_txt[object$validation$validation_set$val_id==.n]=="")){
          HTML(paste0("<font color='red' size='3'>",' ', "</font>"))
        }else{
          txt = unique(object$validation$validation_set$coding_txt[object$validation$validation_set$val_id==.n])
          HTML(paste0("<font color='#ef5d56' size='4' > <strong>",txt, "</strong></font>"))
        }
      })
    })


    # Recursive buttons and data profile on the output frame
    observeEvent(input$choice1,{
      object$validation$validation_set$coding[object$validation$validation_set$val_id==.n][2] <<- 1
      object$validation$validation_set$coding[object$validation$validation_set$val_id==.n][3] <<- 0
      object$validation$validation_set$coding[object$validation$validation_set$val_id==.n][4] <<- 0
      object$validation$validation_set$coding_txt[object$validation$validation_set$val_id==.n][1:4] <<- txt <- "Entry A is the best match."
      output$status_1 <-  renderText({
        HTML(paste0("<font color='#ef5d56' size='4' > <strong>",txt, "</strong></font>"))
      })
    })
    observeEvent(input$choice2,{
      object$validation$validation_set$coding[object$validation$validation_set$val_id==.n][2] <<- 0
      object$validation$validation_set$coding[object$validation$validation_set$val_id==.n][3] <<- 1
      object$validation$validation_set$coding[object$validation$validation_set$val_id==.n][4] <<- 0
      object$validation$validation_set$coding_txt[object$validation$validation_set$val_id==.n][1:4] <<- txt <- "Entry B is the best match."
      output$status_1 <-  renderText({
        HTML(paste0("<font color='#ef5d56' size='4' > <strong>",txt, "</strong></font>"))
      })
    })
    observeEvent(input$choice3,{
      object$validation$validation_set$coding[object$validation$validation_set$val_id==.n][2] <<- 0
      object$validation$validation_set$coding[object$validation$validation_set$val_id==.n][3] <<- 0
      object$validation$validation_set$coding[object$validation$validation_set$val_id==.n][4] <<- 1
      object$validation$validation_set$coding_txt[object$validation$validation_set$val_id==.n][1:4] <<- txt <- "Entry C is the best match."
      output$status_1 <-  renderText({
        HTML(paste0("<font color='#ef5d56' size='4' > <strong>",txt, "</strong></font>"))
      })
    })

    # Navigation buttons and resets
    observeEvent(input$next1, {
      if(.n < max(object$validation$validation_set$val_id)){
        isolate({.n <<- .n + 1})
      }
    })
    observeEvent(input$back1, {
      if(.n>1){
        isolate({.n <<- .n - 1})
      }
    })

    # Clear Buttons
    observe({if(input$next1 >= 1){reset("next1")}})
    observe({if(input$back1 >= 1){reset("back1")}})


    # Quit App
    observeEvent(input$quit,{
      object$validation$placeholder <<- .n
      cat("Input object has been overwritten, retaining current work.\n\n")
      # Export main data object on cancel
      stopApp((function(key,val,pos) assign(key,val,envir = as.environment(pos)))(as.character(obj_name),object,1L))
      # stopApp(object)
    })

  }


  if(any(object$validation$validation_set$coding_txt=="")){

    # If there are any values that have yet to be validated, Run app
    shinyApp(.ui, .server)

  } else{

    # CALCULATE ACCURACTY STATISTICS ------------------------------------------------
    reviewed = object$validation$validation_set
    reviewed$match = as.numeric(reviewed$type == 'matching_entry')
    reviewed = drop_na(reviewed)

    TP  = sum(reviewed$match == 1 & reviewed$coding == 1)/nrow(reviewed)
    FP  = sum(reviewed$match == 1 & reviewed$coding == 0)/nrow(reviewed)
    TN  = sum(reviewed$match == 0 & reviewed$coding == 0)/nrow(reviewed)
    FN  = sum(reviewed$match == 0 & reviewed$coding == 1)/nrow(reviewed)
    TPR = TP + TN
    FPR = FP + FN


    # Save rates in object
    object$validation$rates <- list("True Positive Rate"=round(TPR,3),
                                    "False Positive Rate"=round(FPR,3))

    # Print accuracty output
    rates = matrix(paste0(round(c(TPR,FPR),3)*100,"%"),1,2)
    cat("\n\nMELTT Performance Accuracy of Integrated Sample \n")
    cat("",paste0(rep("---",12),collapse=""),"\n")
    cat("TPR: ",rates[1],"\n")
    cat("FPR: ",rates[2],"\n")
    cat("",paste0(rep("---",12),collapse=""),"\nA sample of",nrow(reviewed)/3,"observations --",
        round(object$validation$params$sample_proportion*100,2)
        ,"% of the matched pairs -- from the integrated data were manually reviewed.",
        "2 controls (entries not identified as matches) were randomly drawn from pool of events in proximity for each match.")
    (function(key,val,pos) assign(key,val,envir = as.environment(pos)))(as.character(obj_name),object,1L)
  }


}
