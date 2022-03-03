\name{mplot}
\alias{mplot}
\title{
Wrapper to generate an interactive spatial plot of meltt output data via Leaflet.
}
\description{
\code{mplot} provides an interactive javascript map to plot the spatial distribution of duplicate and unique entries in the integrated data.
}
\usage{
mplot(object, matching = FALSE, jitter=.0001)
}
\arguments{
  \item{object}{
  object of class \code{\link{meltt}}.
}
\item{matching}{
  if TRUE, plot only matching entries (i.e. duplicates and matches), else plot unique and matching entries. Default = \code{FALSE}.
}
\item{jitter}{
  Numeric value to randomly offset longitude and latitude of points for plotting. Useful when points overlap. Default is a small jitter of .0001 degrees.
}
}
\details{
\code{mplot} generates a spatial map using javascript via the \code{Leaflet} package. The map identifies unique and duplicative (i.e. entries with "matches") entries. The function provides a concise summary of the integration output across the spatial bounds of the geo-referenced input data. Plot renders in the users viewer pane (if using RStudio) or in browser. Images of the map can be saved using the export button.
}
\value{
Returns a javascript map, which renders in the user's viewer pane, of all unique event locations (or duplicate and matching entries if \code{matching=} argument is true). Each unique event are denoted as orange circles, matching entries as blue circles, and duplicate entries as green entries.

}
\references{
Karsten Donnay, Eric T. Dunford, Erin C. McGrath, David Backer, David E. Cunningham. (2018). "Integrating Conflict Event Data." \emph{Journal of Conflict Resolution}.
}
\author{
  Karsten Donnay and Eric Dunford.
}
\seealso{
  \code{\link{meltt}}, \code{\link{tplot}}
}
\examples{
\donttest{
data(crashMD)
output = meltt(crash_data1, crash_data2, crash_data3,
                taxonomies = crash_taxonomies, twindow = 1,spatwindow = 3)

mplot(output)
}
}
