mplot <- function(object,interactive=FALSE){
  # Interactive Map function for meltt output data.

  if(!is.meltt(object)) stop("Object is not of class meltt")
  latitude <- longitude <- dataset <- NULL

  # Color Pallete
  colors_pal = c("#8DD3C7","#80B1D3","#FDB462","#FB8072","#BEBADA",
                 "#B3DE69","#FCCDE5","#D9D9D9","#BC80BD","#CCEBC5","#FFED6F")

  # Isolate Unique Events
  loc = meltt.data(object)
  loc$uID = paste0(loc$dataset,"-",loc$event)

  # ID Matches and their Duplicates
  total_n_dats = length(object$inputData)
  matches = meltt.duplicates(object)[,1:(total_n_dats*2)] 
  cols = (1:ncol(matches))[1:ncol(matches) %% 2 == 1]
  match_id = matrix(nrow=nrow(matches),ncol=length(cols))
  for (c in 1:length(cols)) {
    matches[,cols[c]] = object$inputDataNames[c]
    match_id[,c] = paste0(matches[,cols[c]],"-",matches[,cols[c]+1])
  }
  # Edit out fillers
  blacklist = paste0(object$inputDataNames,"-0")
  match_id[match_id %in% blacklist] = NA

  # Clean Set
  l = apply(match_id,1,function(x){
    s = x[which(!is.na(x))]
    data.frame(mID=s[1],duplicates = paste(s[-1],collapse=", "),stringsAsFactors = F)
  })
  match_set = data.frame(matrix(unlist(l),nrow=length(l),byrow = T),stringsAsFactors = F)

  # Join
  loc2 = merge(loc,match_set,by.x="uID",by.y="X1",all.x=T)
  loc2$Type = NA
  loc2[!is.na(loc2$X2),3] = "Match"
  loc2[!is.na(loc2$X2),"Type"] = "Duplicate Events Located"
  loc2[is.na(loc2$X2),"Type"] = "Unique Event"
  colnames(loc2)[colnames(loc2)=="X2"] = "Duplicate_Events"
  loc2$Event_ID = loc2$uID
  # Establish Color Scheme
  loc2$color=NA;loc2$color[loc2$dataset=="Match"] = "dodgerblue2"
  colnames(loc2)[colnames(loc2)=="uID"] = "Event_ID"
  set = unique(loc2$dataset)[unique(loc2$dataset)!="Match"]
  for(s in 1:length(set)){loc2$color[loc2$dataset==set[s]] = colors_pal[s]}

  # Partialing Data Types
  match_loc = loc2[loc2$dataset=="Match",]
  unique_loc = loc2[loc2$dataset!="Match",]


  if(interactive){ # if interactive map

    # Curate input features of the interactive map.
    id_data_match <- match_loc[,c("Type","Event_ID",'Duplicate_Events','date',object$taxonomy$taxonomy_names)]
    id_data_unique <- unique_loc[,c("Type","Event_ID",'Duplicate_Events','date',object$taxonomy$taxonomy_names)]

    # Prevent conversion to numeric
    id_data_match$date = as.character(id_data_match$date)
    id_data_unique$date = as.character(id_data_unique$date)

    # Match Map Set up
    coordinates(match_loc) <- ~ longitude + latitude
    proj4string(match_loc) <- CRS("+proj=longlat +datum=WGS84")
    match_loc2 <- SpatialPointsDataFrame(match_loc, data = id_data_match)
    ic_match <- iconlabels(attribute = match_loc$dataset, colPalette=match_loc$color,
                           icon=T,at=NULL, height=10, scale=0.6)

    # Unique Map Set up
    coordinates(unique_loc) <- ~ longitude + latitude
    proj4string(unique_loc) <- CRS("+proj=longlat +datum=WGS84")
    unique_loc2 <- SpatialPointsDataFrame(unique_loc, data = id_data_unique)
    ic_unique <- iconlabels(attribute = unique_loc$dataset, colPalette=unique_loc$color,
                            icon=T,at=NULL, height=10, scale=0.6)

    tmp <- tempfile() # Temp File to store maps (to guarantee stable render)

    # Generate Interactive Maps
    m1 <- plotGoogleMaps(unique_loc2, filename=tmp,legend=F,
                        mapTypeId = "terrain",
                        layerName = "Unique Entries",
                        visible = T,iconMarker=ic_unique,flat = F,add=T)
    m2 <- plotGoogleMaps(match_loc2, filename=tmp,legend=F,
                        previousMap = m1,
                        mapTypeId = "terrain",
                        layerName = "Entries with Duplicates",
                        visible = T,iconMarker=ic_match,flat = F)

    # Alert message given issues with existing plotGoogleMaps function
    cat("\n\nNote interactive map will not render on Safari browser. Change default browser if issues occur. Interactive feature functions best on Google Chrome.\n\n")

  } else{ # else generate static map
    tt <- rbind(match_loc,unique_loc)
    bounds <- make_bbox(tt$longitude, tt$latitude, f = 0.4)
    feature_map <- suppressWarnings(suppressMessages(get_map(location=bounds,source="google",
                                           maptype = "roadmap",color = "bw",
                                           messaging = FALSE)))
    map <- suppressWarnings(suppressMessages(ggmap(feature_map,extent="device",legend="topright")))

    # Add Features
    theme_set(theme_bw(16))
    cols <- unique(tt[,c("dataset","color")])
    cols$shape <- 8
    cols[cols=="Match","shape"] <- 18
    map + geom_point(data=tt,
                     aes(y=jitter(latitude,.2),x=jitter(longitude,.3),
                         color=factor(dataset,levels = c("Match",set)),
                         shape=factor(dataset,levels = c("Match",set))),
                     size=3,alpha=1) +
      scale_shape_manual(labels=cols$dataset, values=cols$shape) +
      scale_color_manual(labels=cols$dataset,values = cols$color) +
      
      # To make points more prominent
      geom_point(data=tt[tt$dataset=="Match",],
                 aes(y=jitter(latitude,.2),x=jitter(longitude,.3)),
                 size=3.5,shape=18,color="dodgerblue2")+ 
      theme(legend.position="bottom",
            legend.key = element_blank(),
            plot.margin = unit(c(.5,.5,.5,.5), "cm"),
            legend.background = element_blank(),
            legend.title = element_blank())
  }
}
