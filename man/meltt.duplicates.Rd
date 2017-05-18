\name{meltt.duplicates}
\alias{meltt.duplicates}
\title{
Return identified duplicate entries removed after integration.
}
\description{
\code{meltt.duplicates} returns all matching entries that are identified as matches during the integration process.
}
\usage{
meltt.duplicates(object,columns=NULL)
}
\arguments{
  \item{object}{
  object of class \code{\link{meltt}}.
}
  \item{columns}{
  string vector referencing column names located in the input data. Default is to return all columns contained in the input data.
}
}
\details{
\code{meltt.duplicates} returns all duplicated entries along with specified columns to compare which entries matched. Function allows for easy extraction all entries identified as duplicates.
}
\value{
Returns an \code{data.frame} where the first columns contain an index for the data.source and event for each data frame. The subsequent columns are all columns specified in the \code{columns} argument, or all columns contained in the original input data if \code{columns = NULL}.

An "event_type" column is added to the output \code{data.frame} specifying if the match was between events or episode. See \code{\link{meltt.inspect}} for handling flagged event-to-episode matches.
}
\references{
Karsten Donnay, Eric Dunford, Erin C. McGrath, David Backer, David E. Cunningham. (2016). "MELTT: Matching Event Data by Location, Time and Type." Paper presented at \emph{Annual Conference of the Midwest Political Science Association}, April 7-10 2016, Chicago.
}
\author{
  Karsten Donnay and Eric Dunford.
}
\seealso{
  \code{\link{meltt}}, \code{\link{meltt.data}}, \code{\link{meltt.inspect}}
}
\examples{
\dontrun{
data(crashMD)
output <- meltt(crash_data1,crash_data2,crash_data3,
                taxonomies = crash_taxonomies,twindow = 1,spatwindow = 3)
duplicates <- meltt.duplicates(output,column=c("date","longitude","latitude"))
head(duplicates)
}
}
