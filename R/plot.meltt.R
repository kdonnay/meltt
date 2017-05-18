plot.meltt <- function(x,...){
  # Plots a bar graph to summarize output overlap
  
  # BARPLOT
  uniq_entries = as.data.frame(table(x$processed$deduplicated_index[,1]),stringsAsFactors = F)
  total_entries = as.data.frame(table(x$processed$complete_index[,1]),stringsAsFactors = F)
  total_entries$Var1 = x$inputDataNames
  duplicates = total_entries$Freq - uniq_entries$Freq
  df = data.frame(data=c(total_entries$Var1),
                  total=c(total_entries$Freq),
                  unique=c(uniq_entries$Freq),
                  duplicates = duplicates,
                  stringsAsFactors = F)
  colors_pal = c("#8DD3C7","#80B1D3","#FDB462","#FFFFB3","#FB8072","#BEBADA",
                 "#B3DE69","#FCCDE5","#D9D9D9","#BC80BD","#CCEBC5","#FFED6F")
  colors = c("black",colors_pal[1:nrow(df)-1])
  bp <- barplot(df$total, main="", horiz=T,
                names.arg = df$data,col=alpha(colors,.5),border="white",ylim=c(0,5))
  barplot(df$unique, main="", horiz=T,add = T,,axes = F,col=colors,border="white")
  text(x = (df$total-df$duplicates)*.5,y=bp,labels = df$unique)
  text(x = (df$total)*.9,y=bp,labels = df$duplicates,col=alpha("black",.6))
  text(x = (df$total[1])*.5,y=bp[1],labels = df$total[1],col="white")
  text(x = max(df$total)*.15,y=bp[nrow(bp)]+.75,labels ="Unique",font = 2)
  text(x = max(df$total)*.7,
       y=bp[nrow(bp)]+.75,labels ="Duplicates",col=alpha("black",.6),font = 2)
}
