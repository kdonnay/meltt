\name{summary.meltt}
\alias{summary.meltt}
\title{
Summary function for objects of class meltt.
}
\description{
Overloads the default \code{summary()} for objects of class \code{meltt}.
}
\usage{
\method{summary}{meltt}(object, ...)
}
\arguments{
  \item{object}{
  object of class \code{\link{meltt}}.
}
  \item{\dots}{
  further arguments passed to or from other methods.
}
}
\value{
Prints a number of summary statistics regarding inputs (datasets, spatial and temporal windows, taxonomies) and observations (unique, matching, duplicate entries removed). It also prints and returns a \code{data.frame} summarizing the overlap among datasets, i.e., how many entries in any one dataset match up to entries in one or more of the other.
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