mplot <- function(object,matching = FALSE,jitter=.0001){
  UseMethod("mplot")
}

# Variable declaration to satisfy CRAN check
utils::globalVariables(c('key', 'val', 'index', 'dataset', 'event', 'color', 'longitude','latitude', 'type', 'descr', '.'))

mplot.meltt <- function(object,matching = FALSE,jitter=.0001){

  # Isolate Unique Entries
  unis = meltt_data(object,c("dataset","event","longitude","latitude")) %>%
    mutate(type="Unique")

  # Isolate Duplicate Entries
  all_duplicates = meltt_duplicates(object)
  dups = all_duplicates %>%
    select(contains("_dataset"),contains("_eventID"),contains("_lon"),contains("_lat")) %>%
    mutate(index = 1:nrow(all_duplicates)) %>%
    gather(key,val,-index) %>%
    mutate(dataset = gsub("_dataset|_eventID|_lat+\\w+|_lon\\w+|_lat|_lon","",key),
           event = ifelse(grepl("_eventID",key),val,NA),
           longitude = ifelse(grepl("_long*",key),val,NA),
           latitude = ifelse(grepl("_lat*",key),val,NA)) %>%
    select(index,dataset,event,longitude,latitude)

  # Parse
  simple_filter = function(x,...){x %>% select(index,dataset,...) %>% drop_na(.)}

  dups_all <-
    inner_join(
      dups %>% simple_filter(event),
      dups %>% simple_filter(longitude),
      by = c("index", "dataset")
    ) %>%
    inner_join(
      dups %>% simple_filter(latitude),
      by = c("index", "dataset")
    )

  # Gather Data
  loc <-
    full_join(unis,dups_all,by = c("dataset","event", "latitude", "longitude")) %>%
    mutate(type = ifelse(is.na(type),"Duplicate",type),
           type = ifelse(type == "Unique" & !is.na(index),"Match",type),
           color = ifelse(type=="Unique","orange",
                          ifelse(type=="Duplicate","#8DD3C7",
                                 ifelse(type=="Match","#217dce",NA))),
           fillOpacity = ifelse(type=="Match",.7,.1)
    ) %>%

    # Build Description
    group_by(index) %>%
    mutate(descr = paste0("entry ",dataset[-1],"-",unique(event[-1]),collapse = " and "),
           descr = ifelse(is.na(index),NA,paste0("Entry ",dataset[1],"-",event[1]," matched with ",descr)),
           descr = ifelse(type=="Duplicate",paste0("duplicate of event ",dataset[1],"-",event[1]),descr)) %>%
    group_by(dataset,event) %>%
    mutate(descr = ifelse(type=="Unique",paste0("Entry ",dataset[1],"-",event[1]," is unique"),descr),
           descr = ifelse(type=="Duplicate",paste0("Entry ",dataset[1],"-",event[1]," is a ",descr),descr)) %>%
    ungroup() %>%

    # Jitter locations slightly so points don't overlap
    mutate(longitude = jitter(longitude,amount = jitter),
           latitude = jitter(latitude,amount = jitter))

  # Determine if only unique or only matching
  if(matching){
    loc <- filter(loc,type!="Unique")
  }else{
    loc <- filter(loc,type!="Duplicate")
  }

  # colors for legend
  col_labels = loc %>% select(color,type) %>% unique

  # Generate interactive plot using leaflet
  leaflet(loc) %>%
    addTiles() %>%
    addProviderTiles(provider = "Esri.WorldTopoMap") %>%
    addCircleMarkers(~longitude, ~latitude,color=loc$color,popup =~as.character(descr),
                     label =~as.character(descr),
                     stroke = T, fillOpacity = loc$fillOpacity) %>%
    addLegend("bottomright", colors = col_labels$color, labels = col_labels$type,
              title = "",opacity = 1) %>%
    addMiniMap()
}