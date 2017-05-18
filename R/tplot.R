tplot = function(object,time.unit="month"){
  # Time Series Plot for Meltt Output Data

  if(!is.meltt(object)) stop("Object is not of class meltt")

  n.datasets = length(object$inputDataNames)
  key = object$processed$deduplicated_index[,c(1,2)]
  d.sets = object$inputDataNames
  colors_pal = c("#8DD3C7","#80B1D3","#FDB462","#FFFFB3","#FB8072","#BEBADA",
                 "#B3DE69","#FCCDE5","#D9D9D9","#BC80BD","#CCEBC5","#FFED6F")
  colors = c("black",colors_pal[1:length(d.sets)-1])

  for(d in seq_along(d.sets)){
    if(d==1){unique_dates=c();dup_dates=c();base=c()}
    sub = object$inputData[[d]]
    base = rbind(base,sub[,c("data.source","date")])
    unique_dates = rbind(unique_dates,sub[sub$obs.count %in% key[key[,1] == d,2],][,c("data.source","date")])
    dup_dates = rbind(dup_dates,sub[!sub$obs.count %in% key[key[,1] == d,2],][,c("data.source","date")])
  }


  # Break up by specified temporal unit
  unique_dates$unit <-  as.Date(cut(unique_dates$date,breaks = time.unit,start.on.monday = FALSE))
  dup_dates$unit <-  as.Date(cut(dup_dates$date,breaks = time.unit,start.on.monday = FALSE))
  base$unit <-  as.Date(cut(base$date,breaks = time.unit,start.on.monday = FALSE))
  # ensure alignment
  frame = data.frame(unit=unique(base$unit))
  dup_dates = merge(frame,dup_dates,by="unit",all.x=T)
  unique_dates = merge(frame,unique_dates,by="unit",all.x=T)
  dup_dates$data.source[is.na(dup_dates$data.source)] = NA
  unique_dates$data.source[is.na(unique_dates$data.source)] = NA

  # ylow = max(table(dup_dates$unit))
  yhigh = max(table(unique_dates$unit))
  bp=barplot(table(unique_dates$data.source,unique_dates$unit),
             col=colors,border="white",
             ylim=c(-yhigh-round(yhigh*.3),yhigh+round(yhigh*.3)),
             # ylim=c(-ylow-round(ylow*.3),yhigh+round(yhigh*.3)),
             xlab=paste0("Date by ",time.unit),ylab="Count",
             main = "",axisnames=F)
  barplot(-table(dup_dates$data.source,dup_dates$unit),
          add=T,border="white",col=alpha(colors[-1],.65),
          ylab="",axisnames=F)
  abline(h=0,lwd=2)
  text(bp[1],yhigh+(yhigh*.15),"Unique",font = 2,cex=.8)
  text(bp[1],-yhigh-(yhigh*.15),"Duplicates",font = 2,col=alpha("black",.6),cex=.8)
  # text(bp[1],-ylow-(ylow*.15),"Duplicates",font = 2,col=alpha("black",.6),cex=.8)
  legend("bottomright",d.sets,fill=colors,
         cex=.8,pt.cex = .01,ncol=n.datasets,border="white",bty = "n")
}

