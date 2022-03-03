\name{tplot}
\alias{tplot}
\title{
Temporal distribution of meltt output data.
}
\description{
\code{tplot} provides a histogram of integrated data that plots the temporal distribution of duplicate and unique entries
}
\usage{
tplot(object, time_unit = "months", free_scale = TRUE)
}
\arguments{
  \item{object}{
  object of class \code{\link{meltt}}.
}
  \item{time_unit}{
  character specifying the temporal bin: \kbd{"days"}, \kbd{"weeks"}, \kbd{"months"}, and \kbd{"years"}. \code{Default = "months"}.
}
 \item{free_scale}{
  boolean if duplicates should be presented on a different scale from unique entries. A free scale makes it easier to assess the number of duplicate entries and from which input data they emerge, given that there can be relatively few at times. \code{Default = TRUE}.
}
}
\details{
\code{tplot} generates a temporal histogram that identifies unique entries after duplicates are removed and a reverse temporal histogram charting the distribution of duplicate entries. The function provides a concise summary of the integration output across the input time period presented in a relevant unit.
}
\value{
Returns a histogram plot where the y-axis is a frequency capturing the total number of events for that time period, and the x-axis is time.
}
\references{
Karsten Donnay, Eric T. Dunford, Erin C. McGrath, David Backer, David E. Cunningham. (2018). "Integrating Conflict Event Data." \emph{Journal of Conflict Resolution}.
}
\author{
  Karsten Donnay and Eric Dunford.
}
\seealso{
  \code{\link{meltt}}, \code{\link{mplot}}
}
\examples{
\donttest{
data(crashMD)
output = meltt(crash_data1, crash_data2, crash_data3,
                      taxonomies = crash_taxonomies, twindow = 1, spatwindow = 3)

# Free scale
tplot(output, time_unit = "days")

# Relative scale
tplot(output, time_unit = "days", free_scale = FALSE)
}
}
