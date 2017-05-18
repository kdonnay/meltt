\name{meltt.inspect}
\alias{meltt.inspect}
\title{
Returns flagged event-to-episode matches for review.
}
\description{
\code{meltt.inspect} returns all episode entries that were flagged to match to an event. Function provides a list containing each flagged event and episode to ease comparison and assessment. All flagged entries should be manually reviewed to determine the validity of the match.

If an flagged event-to-episode is determined to be a match, the duplicate can be removed by providing a Boolean vector to the \code{confirmed_matches} argument. All \code{TRUE} episodes will be removed as duplicates, retaining only the event entry.
}
\usage{
meltt.inspect(object,columns=NULL,confirmed_matches=NULL)
}
\arguments{
  \item{object}{
  object of class \code{\link{meltt}}.
}
  \item{columns}{
  string vector referencing column names located in the input data. Default is to return all location, time stamp, and taxonomy columns the data was evaluated on.
}
  \item{confirmed_matches}{
  boolean vector specifying entries to be removed from deduplicated set. Function returns a \code{data.frame} of unique, deduplicated entries when specified.
}
}
\details{
\code{meltt.inspect} returns all episode entries that were flagged to match to an event. Function provides a list containing each flagged event and episode for easy comparison. Matching event-to-episodes can be cleaned by specifying a boolean vector where \code{TRUE} identifies that entry as a duplicate, otherwise \code{FALSE}
}
\value{
Returns a \code{list} object where each entry in the list contains information on the event and the flagged episode for manual assessment of the match. The information by which the entries are evaluated are specified by the \code{columns} argument. If \code{columns = NULL},location, time stamp, and taxonomy information is reported.

Events and episodes confirmed as duplicate entries can be removed by providing a boolean vector to the \code{confirmed_matches} argument. A \code{data.frame} of unique entries (similar to the output of \code{meltt.data}) will be returned.
}
\references{
Karsten Donnay, Eric Dunford, Erin C. McGrath, David Backer, David E. Cunningham. (2016). "MELTT: Matching Event Data by Location, Time and Type." Paper presented at \emph{Annual Conference of the Midwest Political Science Association}, April 7-10 2016, Chicago.
}
\author{
  Karsten Donnay and Eric Dunford.
}
\seealso{
  \code{\link{meltt}}, \code{\link{meltt.data}}, \code{\link{meltt.duplicates}}
}
\examples{
\dontrun{
data(crashMD)
output <- meltt(crash_data1,crash_data2,crash_data3,
                taxonomies = crash_taxonomies,twindow = 1,spatwindow = 3)

flagged <- meltt.inspect(output)
flagged

retain <- c(TRUE,TRUE,TRUE,TRUE,TRUE)
dataset <- meltt.inspect(output,confirmed_matches=retain)
head(dataset)
}
}
