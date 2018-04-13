\name{meltt.episodal}
\alias{meltt.episodal}
\title{
Handling events and episodal data [Auxiliary Function]
}
\description{
Auxiliary function that receives the compilation matrix and systematically subsets events and episodes to deal with differences in event duration. The function passes subsets to \code{meltt.match}to be processed. Output includes a full list of matching events and/or episodes. 
}
\usage{
meltt.episodal(data, indexing, priormatches, twindow, spatwindow,
	       smartmatch, certainty, k, secondary, partial, averaging, weight)
}
\arguments{
  \item{data}{
  object of class data.frame. 
}
  \item{indexing}{
  list of indices given the entry location of events and episodes in the original input data.
}
 \item{priormatches}{
  prior matches (if any) passed as \code{data.frame}. 
}
  \item{twindow}{
  specification of temporal window in unit days. 
}
  \item{spatwindow}{
  specification of a spatial window in kilometers.
}
  \item{smartmatch}{
  implement matching using all available taxonomy levels. When false, matching will occur only on a specified taxonomy level. Default = \kbd{TRUE}. 
}
 \item{certainty}{
  specification of the the exact taxonomy level to match on when \code{smartmatch} = \kbd{F}. Default = \kbd{NULL}. 
}
 \item{k}{
  number of taxonomies passed from \code{meltt}. 
}
 \item{secondary}{
  vector of the number of taxonomy levels for each taxonomy passed from \code{meltt}. 
}
 \item{partial}{
  specifies whether matches along less than the full taxonomy dimensions are permitted. Passed from \code{meltt}. 
}
  \item{averaging}{
  implement averaging of all values events are match on when matching across multiple dataframes. Default = \kbd{FALSE}. 
}
  \item{weight}{
  relative weight of each taxonomy in the calculation of the matching score. Passed from \code{meltt}. 
}
}
\details{
Internal function that helps manage integration of event and episodal data by easing the transition between the two logics. \code{meltt} algorithm tracks event-to-event matches, episode-to-episode, and event-to-episode matches. \code{meltt.episodal} streamlines the transfer between these matching states.
}
\references{
Karsten Donnay, Eric T. Dunford, Erin C. McGrath, David Backer, David E. Cunningham. (2018). "Integrating Conflict Event Data." \emph{Journal of Conflict Resolution}.
}
\author{
Karsten Donnay and Eric Dunford.
}
\seealso{
\code{\link{meltt}}
}