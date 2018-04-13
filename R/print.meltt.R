print.meltt <- function(x, ...){
  orig_N = nrow(x$processed$complete_index)
  unique_N = nrow(x$processed$deduplicated_index)
  overlap_N = orig_N - unique_N
  match_N = nrow(x$processed$event_matched)  + nrow(x$processed$episode_matched)
  N_data_entries = length(x$inputDataNames)
  main = paste0("MELTT Complete: ",N_data_entries," datasets successfully integrated.\n")
  rep2 = function(txt,n) paste0(rep(txt,n),collapse="")
  message = paste0(main,paste(rep("===",19),collapse=""),"\n",
                   "Total No. of Input Observations:",rep2(" ",18),orig_N,"\n",
                   "No. of Unique Obs (after deduplication):",rep2(" ",10),unique_N,"\n",
                   "No. of Unique Matches:",rep2(" ",28),match_N,"\n",
                   "No. of Duplicates Removed:",rep2(" ",24),overlap_N,"\n",
                   paste(rep2("===",19),collapse=""))
  cat(message)

}