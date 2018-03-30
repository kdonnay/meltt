plot.meltt <- function(x,...){

  # Gather statistics
  df <-
    tibble(source = x$inputDataNames,
           total=table(x$processed$complete_index[,1]),
           'Unique Entries'=table(x$processed$deduplicated_index[,1]),
           'Duplicate Entries' = total-`Unique Entries`) %>%
    select(-total) %>%
    gather(key,value,-source) %>%
    mutate(value=as.integer(value),
           value = ifelse(key=="Duplicate Entries",-value,value),
           key = factor(key,levels=c("Unique Entries","Duplicate Entries"))) %>%
    filter(value!=0) %>%
    group_by(source) %>%
    mutate(prop=round(abs(value)/sum(abs(value)),2),
           prop = paste0(prop*100,"%"))

  # Color Scheme
  colors_pal = c("#8DD3C7","#80B1D3","#FDB462","#FFFFB3","#FB8072","#BEBADA",
                 "#B3DE69","#FCCDE5","#D9D9D9","#BC80BD","#CCEBC5","#FFED6F")
  colors = c("black",colors_pal[1:length(x$inputDataNames)-1])

  # Plot
  ggplot() +
    geom_bar(data=df[df$key=="Unique Entries",],aes(x=source,y=value,fill=source),stat="identity") +
    geom_bar(data=df[df$key=="Duplicate Entries",],aes(x=source,y=value,fill=source),
             stat="identity",alpha=.5) +
    geom_text(data=df,aes(x=source,y=value,
                          label=paste0(abs(value)," (",prop,")"),
                          color=source),
              position = position_stack(vjust = 0.5,reverse = T)) +
    coord_flip() +
    scale_y_reverse() +
    scale_fill_manual(values=colors) +
    scale_color_manual(values=c("white",rep("black",length(x$inputDataNames)-1))) +
    theme_light()  +
    facet_wrap(~key,scales = "free_x") +
    labs(y="Count",x="") +
    theme(legend.position = "none")
}
