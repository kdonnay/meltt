meltt.taxonomy <- function(data,taxonomies){
  # INPUT: Amalgamated data frame (internal to meltt); taxonomies data as a list
  # OUTPUT: numerical taxonomy, cbinded together, secondary input, and k
  processed_taxonomies <- c() # Output Bin
  tax_names <- names(taxonomies) # Specific Taxonomies
  issue_message<- c()

  for (i in 1:length(tax_names)){
    # Loop through taxonomies inputed as a list, map onto the existing data, and
    # save as a numerical matrix

    inputs <- data[,c("data.source","obs.count",tax_names[i])]
    temp_tax <- as.data.frame(taxonomies[[i]])


    # TAXONOMY CLEANING
    for (tax.cols in 1:ncol(temp_tax)){
      if (is.character(temp_tax[,tax.cols]) | is.factor(temp_tax[,tax.cols])){
        temp_tax[,tax.cols] <- trimws(temp_tax[,tax.cols])
      }
    }

    # MAKE index ---------
    base.category <- data.frame(data.source = inputs[,1], base.category=inputs[,3],stringsAsFactors = F)

    cats <- base.category$base.category # Subset Base Categories
    sub_temp_tax <- temp_tax[temp_tax$data.source==unique(inputs$data.source),] # Subset Taxonomy

    # CHECK to ensure all base.categories are present in the input data
    ucats = unique(cats)
    check = ucats[!(ucats %in% sub_temp_tax[,2])]
    if(length(check)>0){
      if(length(issue_message)==0){pos=1;issue_message = append(issue_message,paste0("\nTaxonomy Error located in the '",unique(inputs$data.source),"' input dataset:\n\n"))}
      issue_message <- append(issue_message,paste0("\t(",pos,") The '",tax_names[i],
                                                   "' variable does not map onto the base\n\tcategories provided by the ",tax_names[i]," taxonomy!\n",
                                                   "Specifically, the following categories fail to map:\n\t\t=> ",paste0(check,collapse=", "),"\n\n"))
      pos = pos + 1
    }

    tax.columns <- sub_temp_tax[base::match(cats,sub_temp_tax[,2]),1:ncol(sub_temp_tax)]
    tax_master_columns <- tax.columns
    row.names(tax_master_columns) <- NULL

    tax_master_columns = tax_master_columns[,1:2*-1] # Drop Index
    if(is.null(ncol(tax_master_columns))){
      tax_master_columns = as.data.frame(tax_master_columns)
      colnames(tax_master_columns) <- paste0(tax_names[i],"_level_",1) # rename column
    }else{
      colnames(tax_master_columns) <- paste0(tax_names[i],"_level_",1:ncol(tax_master_columns)) # rename column
    }


    if(i == 1){
      processed_taxonomies=tax_master_columns
    }else{
      processed_taxonomies <- cbind(processed_taxonomies,tax_master_columns)
    }

  }
  return(list(processed_taxonomies=processed_taxonomies,issue_messages = issue_message))
}