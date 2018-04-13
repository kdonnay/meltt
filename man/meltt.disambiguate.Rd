\name{meltt.disambiguate}
\alias{meltt.disambiguate}
\title{
Tracking and indexing of matching entries [Auxiliary Function]
}
\description{
Auxiliary function used within \code{meltt} to index events as multiple datasets are processed.
}
\usage{
meltt.disambiguate(data, match_output, indexing, priormatches, averaging)
}
\arguments{
  \item{data}{
  data to be disambiguated passed as \code{data.frame} object from \code{meltt}. See details.
}
  \item{match_output}{
  data.frame object of identified matches passed from \code{meltt.match}. See details.
}
  \item{indexing}{
  data.frame object passed from \code{meltt} that specifies the correct index for every event and dataset. See details.
}
  \item{priormatches}{
  prior matches (if any) passed as \code{data.frame}. See details.
}
 \item{averaging}{
  specification if common information among matches should be averaged. Passed from \code{meltt}. See details. 
}
}
\details{
Auxilary function used within \code{meltt} to index events as multiple datasets are processed. Function keeps track of matching and non-matching events as each subsequent data.frame is processed. Using the identified matches from the \code{meltt.match} output, \code{meltt.disambiguate} merges the matches in the data and indexes the match. \code{indexing} is used for correct labeling of matches in case more than two datasets are merged. \code{averaging} averages the common information between matching events. The parameter is specified within the main function \code{meltt}.
}
\value{
\code{meltt.disambiguate} returns a list containing two object: a data frame with all located matches paired and a new index, specifying the data frame as a single frame, and a running index of all matched events.
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