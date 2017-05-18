\name{tplot}
\alias{tplot}
\title{
Temporal distribution of meltt output data.
}
\description{
\code{tplot} provides a histogram of integrated data that plots the temporal distribution of duplicate and unique entries
}
\usage{
tplot(object,time.unit="month")
}
\arguments{
  \item{object}{
  object of class \code{\link{meltt}}.
}
  \item{time.unit}{
  string specifying the temporal bin: "day", "week", "month", and "year". Default = "month".
}
}
\details{
\code{tplot} generates a temporal histogram that identifies unique entries after duplicates are removed and a reverse temporal histogram charting the distribution of duplicate entries. The function provides a concise summary of the integration output across the input time period presented in a relevant unit.
}
\value{
Returns a histogram plot where the y-axis is a frequency capturing the total number of events for that time period, and the x-axis is time.
}
\references{
Karsten Donnay, Eric Dunford, Erin C. McGrath, David Backer, David E. Cunningham. (2016). "MELTT: Matching Event Data by Location, Time and Type." Paper presented at \emph{Annual Conference of the Midwest Political Science Association}, April 7-10 2016, Chicago.
}
\author{
  Karsten Donnay and Eric Dunford.
}
\seealso{
  \code{\link{meltt}}, \code{\link{mplot}}
}
\examples{
\dontrun{
data(crashMD)
output <- meltt(crash_data1,crash_data2,crash_data3,
                      taxonomies = crash_taxonomies,twindow = 1,spatwindow = 3)
tplot(output,time.unit="day")
}
}
