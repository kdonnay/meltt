\name{is.meltt}
\alias{is.meltt}
\title{
Tests for objects of type meltt.
}
\description{
Function returns logical statement whether an object is of class \code{meltt}.
}
\usage{
is.meltt(object)
}
\arguments{
  \item{object}{object to be tested.
}
}
\value{
\code{is.meltt} returns \code{TRUE} or \code{FALSE} depending on whether its argument is of type \code{meltt} or not.
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
\examples{
\donttest{
data(crashMD)
output = meltt(crash_data1,crash_data2,crash_data3,
                taxonomies = crash_taxonomies,twindow = 1,spatwindow = 3)
is.meltt(output)
}
}