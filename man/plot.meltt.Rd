\name{plot.meltt}
\alias{plot.meltt}
\title{
Plot function for objects of class meltt.
}
\description{
Overloads the default \code{plot()} for objects of class \code{meltt}.
}
\usage{
\method{plot}{meltt}(x, ...)
}
\arguments{
  \item{x}{
  object of class \code{\link{meltt}}.
}
  \item{\dots}{
  further arguments passed to or from other methods.
}
}
\details{
Returns a bar plot outlining the proportion of events that are unique and duplicates from an object of class \code{meltt}.
}
\references{
Karsten Donnay, Eric Dunford, Erin C. McGrath, David Backer, David E. Cunningham. (2016). "MELTT: Matching Event Data by Location, Time and Type." Paper presented at \emph{Annual Conference of the Midwest Political Science Association}, April 7-10 2016, Chicago.
}
\author{
  Karsten Donnay and Eric Dunford.
}
\seealso{
  \code{\link{meltt}}
}
\examples{
\dontrun{
data(crashMD)
output <- meltt(crash_data1,crash_data2,crash_data3,
                taxonomies = crash_taxonomies,twindow = 1,spatwindow = 3)
plot(output)
}
}
