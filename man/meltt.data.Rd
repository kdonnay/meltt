\name{meltt.data}
\alias{meltt.data}
\title{
Returns de-duplicated entries from meltt output.
}
\description{
\code{meltt.data} returns all unique, de-duplicated entries across all input datasets. Function provides a dataset where all overlapping, duplicate entries are removed, offering a version of the input data with no redundancies.
}
\usage{
meltt.data(object,columns=NULL)
}
\arguments{
  \item{object}{
  object of class \code{\link{meltt}}.
}
  \item{columns}{
  string vector referencing column names located in the input data. Default is to return all location, time stamp, and taxonomy columns the data was evaluated on.
}
}
\details{
\code{meltt.data} returns all unique entries along with specified columns. Function allows for easy extraction all de-duplicated entries.
}
\value{
Returns an \code{data.frame} where the first columns contains the name of the original input data object from which the data entry was drawn, and a unique event ID. The subsequent columns are all columns specified in the \code{columns} argument, or location, time stamp, and taxonomy columns the data was evaluated on \code{columns = NULL}.
}
\references{
Karsten Donnay, Eric Dunford, Erin C. McGrath, David Backer, David E. Cunningham. (2016). "MELTT: Matching Event Data by Location, Time and Type." Paper presented at \emph{Annual Conference of the Midwest Political Science Association}, April 7-10 2016, Chicago.
}
\author{
  Karsten Donnay and Eric Dunford.
}
\seealso{
  \code{\link{meltt}}, \code{\link{meltt.duplicates}}, \code{\link{meltt.inspect}}
}
\examples{
\dontrun{
data(crashMD)
output <- meltt(crash_data1,crash_data2,crash_data3,
                taxonomies = crash_taxonomies,twindow = 1,spatwindow = 3)
dataset <- meltt.data(output,column=c("date","longitude","latitude"))
head(dataset)

# Return all original columns
dataset <- meltt.data(output,return_all = T)
}
}
