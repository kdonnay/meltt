\name{mplot}
\alias{mplot}
\title{
Generate a Google Map plotting the spatial distribution of meltt output data.
}
\description{
\code{mplot} provides both a static and interactive Google Map plotting the spatial distribution of duplicate and unique entries in the integrated data.
}
\usage{
mplot(object, interactive = FALSE)
}
\arguments{
  \item{object}{
  object of class \code{\link{meltt}}.
}
\item{interactive}{
  Specify if the Google Map should be interactive. Default = \code{FALSE}.
}
}
\details{
\code{mplot} generates a static spatial map using the Google Maps API. The map identifies unique and duplicative (i.e. entries with "matches") entries. The function provides a concise summary of the integration output across the spatial bounds of the geo-referenced input data.

\code{mplot} also generates an interactive spatial map that renders in the user's browser.
}
\value{
Returns a Google Map, which renders in the user's browser if \code{interactive=TRUE}, of all unique event locations. Each unique event from the input data is represented by a unique color. Matching events (i.e. events with detected duplicates) are marked as blue diamonds.

For the interactive map, events where duplicates were identified are flagged as a "Match", and the duplicates for the event are marked in the point meta data. All events are provided a unique identifier which corresponds to the input data's name (i.e. the object name of the input data) and it's location in the input frame (i.e. "dataA-4" corresponds to the fourth entry in the \code{data.frame} "dataA").
}
\references{
Karsten Donnay, Eric Dunford, Erin C. McGrath, David Backer, David E. Cunningham. (2016). "MELTT: Matching Event Data by Location, Time and Type." Paper presented at \emph{Annual Conference of the Midwest Political Science Association}, April 7-10 2016, Chicago.
}
\author{
  Karsten Donnay and Eric Dunford.
}
\seealso{
  \code{\link{meltt}}, \code{\link{tplot}}
}
\examples{
\dontrun{
data(crashMD)
output <- meltt(crash_data1,crash_data2,crash_data3,
                taxonomies = crash_taxonomies,twindow = 1,spatwindow = 3)

mplot(output) # Static Map

mplot(output,interactive=T) # Interactive Map (will render in browser)
}
}
