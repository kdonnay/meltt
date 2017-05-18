print.meltt <- function(x, ...){
  if(is.meltt(x)){
    orig_N = nrow(x$processed$complete_index)
    unique_N = nrow(x$processed$deduplicated_index)
    overlap_N = orig_N - unique_N
    match_N = nrow(x$processed$event_matched)  + nrow(x$processed$episode_matched)
    N_data_entries = length(x$inputDataNames)
    main = paste0("MELTT Complete: ",N_data_entries," datasets successfully integrated.\n")
    message = paste0(main,paste(rep("===",17),collapse=""),"\n",
                     "Total No. of Input Observations:\t\t",orig_N,"\n",
                     "No. of Unique Obs (after deduplication):\t",unique_N,"\n",
                     "No. of Unique Matches:\t\t\t\t",match_N,"\n",
                     "No. of Duplicates Removed:\t\t\t",overlap_N,"\n",
                     paste(rep("===",17),collapse=""))
    cat(message)
  }

}
